use std::{sync::Arc, time::Duration};

use axum::extract::ws::{Message as WsMessage, WebSocket};
use bytes::{Bytes, BytesMut};
use mailrs_smtp_proto::{
    Command, EnhancedCode, Event, Response, Session, SessionConfig, format_ehlo_response,
    parse_command, unstuff_data,
};
use tokio::time::timeout;

use super::{AppState, ClientIp, Error, deliver};

const MAX_COMMAND_BYTES: usize = 1024;
const MAX_BODY_LIMIT_BYTES: usize = 64 * 1024;
pub(super) const MAX_WS_FRAME_BYTES: usize = MAX_BODY_LIMIT_BYTES * 2;
const SMTP_HOSTNAME: &str = "www.sebastianrasor.com";
const GREETING: &[u8] = b"220 www.sebastianrasor.com ESMTP\r\n";
const TIMEOUT_REPLY: &[u8] = b"421 4.4.2 Timeout waiting for client input.\r\n";

impl From<Error> for Response {
    fn from(err: Error) -> Self {
        let message = err.to_string();
        let (code, class, subject, detail) = match err {
            Error::Invalid(_) => (554, 5, 7, 1),
            Error::RateLimited(_) => (451, 4, 7, 1),
            Error::Dns(_) => (451, 4, 4, 3),
            Error::Smtp(_) => (451, 4, 3, 0),
        };
        Self::new(
            code,
            Some(EnhancedCode {
                class,
                subject,
                detail,
            }),
            message,
        )
    }
}

enum Mode {
    Command,
    Data,
}

struct TooLarge;

fn take_frame(
    rx: &mut BytesMut,
    end: Option<usize>,
    max: usize,
) -> Option<Result<BytesMut, TooLarge>> {
    match end {
        Some(end) if end <= max => Some(Ok(rx.split_to(end))),
        Some(_) => Some(Err(TooLarge)),
        None => (rx.len() > max).then_some(Err(TooLarge)),
    }
}

pub(super) async fn serve(mut socket: WebSocket, state: Arc<AppState>, client_ip: ClientIp) {
    if timeout(
        Duration::from_secs(30),
        run_session(&mut socket, &state, client_ip),
    )
    .await
    .is_err()
    {
        let _ = socket
            .send(WsMessage::Binary(Bytes::from_static(TIMEOUT_REPLY)))
            .await;
    }
    let _ = socket.send(WsMessage::Close(None)).await;
}

async fn flush(socket: &mut WebSocket, out: &mut String) -> Result<(), axum::Error> {
    if !out.is_empty() {
        socket
            .send(WsMessage::Binary(Bytes::from(std::mem::take(out))))
            .await?;
    }
    Ok(())
}

async fn run_session(
    socket: &mut WebSocket,
    state: &AppState,
    client_ip: ClientIp,
) -> Result<(), axum::Error> {
    let mut session = Session::new(
        SMTP_HOSTNAME,
        SessionConfig {
            max_size: MAX_BODY_LIMIT_BYTES as u64,
            ..SessionConfig::default()
        },
    );
    let mut mode = Mode::Command;
    let mut rx = BytesMut::new();
    let mut out = String::new();

    socket
        .send(WsMessage::Binary(Bytes::from_static(GREETING)))
        .await?;

    while let Some(Ok(msg)) = socket.recv().await {
        match msg {
            WsMessage::Binary(b) => rx.extend_from_slice(&b),
            WsMessage::Text(t) => rx.extend_from_slice(t.as_bytes()),
            WsMessage::Ping(_) | WsMessage::Pong(_) => continue,
            WsMessage::Close(_) => return Ok(()),
        }

        loop {
            match mode {
                Mode::Command => {
                    let end = rx.windows(2).position(|w| w == b"\r\n").map(|p| p + 2);
                    let Some(frame) = take_frame(&mut rx, end, MAX_COMMAND_BYTES) else {
                        break;
                    };
                    let Ok(raw) = frame else {
                        out.push_str(&Response::syntax_error().format());
                        return flush(socket, &mut out).await;
                    };
                    let Some(cmd) = raw
                        .strip_suffix(b"\r\n")
                        .and_then(|s| str::from_utf8(s).ok())
                        .and_then(|s| parse_command(s).ok())
                    else {
                        out.push_str(&Response::syntax_error().format());
                        continue;
                    };
                    match session.handle_command(&cmd) {
                        Event::Reply(_) if matches!(cmd, Command::Ehlo(_)) => out.push_str(
                            &format_ehlo_response(&session.hostname, &session.capabilities()),
                        ),
                        Event::Reply(resp) => out.push_str(&resp.format()),
                        Event::NeedData { .. } => {
                            mode = Mode::Data;
                            out.push_str(&Response::data_start().format());
                        }
                        Event::Shutdown(resp) => {
                            out.push_str(&resp.format());
                            return flush(socket, &mut out).await;
                        }
                        Event::StartTls(_)
                        | Event::NeedAuth { .. }
                        | Event::AuthChallenge { .. } => {
                            out.push_str(&Response::bad_sequence().format());
                        }
                    }
                }
                Mode::Data => {
                    let end = rx
                        .starts_with(b".\r\n")
                        .then_some(3)
                        .or_else(|| rx.windows(5).position(|w| w == b"\r\n.\r\n").map(|p| p + 5));
                    let Some(frame) = take_frame(&mut rx, end, MAX_BODY_LIMIT_BYTES) else {
                        break;
                    };
                    let Ok(raw) = frame else {
                        out.push_str(&Response::too_large().format());
                        return flush(socket, &mut out).await;
                    };
                    mode = Mode::Command;
                    flush(socket, &mut out).await?;
                    let reply = deliver(state, client_ip, &unstuff_data(&raw))
                        .await
                        .map_or_else(Response::from, |()| Response::data_ok());
                    out.push_str(&reply.format());
                }
            }
        }

        flush(socket, &mut out).await?;
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use axum_test::{TestServer, WsMessage as TestWsMessage};
    use bytes::Bytes;

    use super::{MAX_BODY_LIMIT_BYTES, MAX_COMMAND_BYTES};
    use crate::contact::{Config, app};

    #[tokio::test]
    async fn speaks_esmtp_and_rejects_invalid_submissions_over_websocket() {
        let server = TestServer::builder()
            .http_transport()
            .build(app(Config::default()).unwrap());

        server
            .get_websocket("/contact")
            .add_header("x-real-ip", "not-an-ip")
            .await
            .assert_status_bad_request();

        server
            .get_websocket("/contact")
            .add_header("x-real-ip", "127.0.0.1")
            .add_header("x-real-ip", "127.0.0.2")
            .await
            .assert_status_bad_request();

        let connect = async || {
            server
                .get_websocket("/contact")
                .add_header("x-real-ip", "127.0.0.1")
                .await
                .into_websocket()
                .await
        };

        let mut ws = connect().await;
        assert_eq!(
            String::from_utf8(ws.receive_bytes().await.into()).unwrap(),
            "220 www.sebastianrasor.com ESMTP\r\n"
        );

        let mut send = async |bytes: &'static [u8]| {
            ws.send_message(TestWsMessage::Binary(Bytes::from_static(bytes)))
                .await;
            String::from_utf8(ws.receive_bytes().await.into()).unwrap()
        };

        let ehlo = send(b"EHLO localhost\r\n").await;
        assert!(ehlo.contains("250-PIPELINING\r\n") && ehlo.contains("250 SIZE 65536\r\n"));
        assert!(
            send(b"MAIL FROM:<root@www> SIZE=999999\r\n")
                .await
                .starts_with("552 5.3.4 ")
        );
        assert_eq!(
            send(b"MAIL FROM:<root@www> SIZE=64\r\nRCPT TO:<sebastian@www.sebastianrasor.com>\r\nDATA\r\n").await,
            "250 2.1.0 OK\r\n250 2.1.5 OK\r\n354 Start mail input; end with <CRLF>.<CRLF>\r\n"
        );
        assert_eq!(
            send(b"From: Bot <bot@10minutemail.com>\r\n\r\nHello!\r\n.\r\n").await,
            "554 5.7.1 Invalid sender email address.\r\n"
        );
        let _ =
            send(b"MAIL FROM:<root@www>\r\nRCPT TO:<sebastian@www.sebastianrasor.com>\r\nDATA\r\n")
                .await;
        assert_eq!(
            send(b"Date: Sun, 22 Nov 2026 12:00:00 +0000\r\n\r\n..Dot-stuffed line\r\n.\r\n").await,
            "554 5.7.1 The From header is required.\r\n"
        );
        let _ =
            send(b"MAIL FROM:<root@www>\r\nRCPT TO:<sebastian@www.sebastianrasor.com>\r\nDATA\r\n")
                .await;
        assert_eq!(
            send(b".\r\n").await,
            "554 5.7.1 The message body is required.\r\n"
        );
        assert_eq!(send(b"QUIT\r\n").await, "221 2.0.0 Bye\r\n");
        ws.close().await;

        let half = MAX_BODY_LIMIT_BYTES / 2 + 1;
        for (setup, chunks, code) in [
            (None, vec![vec![b'A'; MAX_COMMAND_BYTES + 1]], "500 "),
            (
                Some(b"EHLO localhost\r\nMAIL FROM:<root@www>\r\nRCPT TO:<sebastian@www.sebastianrasor.com>\r\nDATA\r\n".as_slice()),
                vec![vec![b'x'; half], vec![b'x'; half]],
                "552 ",
            ),
        ] {
            let mut ws = connect().await;
            let _ = ws.receive_bytes().await;
            if let Some(cmd) = setup {
                ws.send_message(TestWsMessage::Binary(Bytes::from_static(cmd)))
                    .await;
                let _ = ws.receive_bytes().await;
            }
            for chunk in chunks {
                ws.send_message(TestWsMessage::Binary(Bytes::from(chunk)))
                    .await;
            }
            assert!(
                String::from_utf8(ws.receive_bytes().await.into())
                    .unwrap()
                    .starts_with(code)
            );
            assert!(matches!(
                ws.receive_message().await,
                TestWsMessage::Close(_)
            ));
        }
    }
}
