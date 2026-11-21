use hickory_resolver::{
    TokioResolver,
    lookup::Lookup,
    proto::rr::{Name, RData},
};
use idna::AsciiDenyList;
use lettre::{
    Address, Message,
    message::{Mailbox, SinglePart},
};
use mail_parser::{Address as ParsedAddress, HeaderName, HeaderValue, MessageParser};

use super::{Config, Error};

const MAX_MESSAGE_BODY_BYTES: usize = 32 * 1024;
const MAX_HEADER_CHARS: usize = 200;
const DEFAULT_SUBJECT: &str = "Website Message";

#[derive(Debug, PartialEq, Eq, thiserror::Error)]
pub(super) enum ParseError {
    #[error("The From header is required.")]
    MissingFrom,
    #[error("The message body is required.")]
    MissingBody,
    #[error("Header values exceed the maximum allowed length.")]
    HeaderTooLong,
    #[error("Header values cannot contain control characters.")]
    InvalidHeader,
    #[error("The message body exceeds the maximum allowed length.")]
    BodyTooLong,
    #[error("Invalid sender email address.")]
    InvalidEmail,
}

fn parse_header(raw: Option<&str>) -> Result<Option<&str>, ParseError> {
    let Some(s) = raw.map(str::trim).filter(|s| !s.is_empty()) else {
        return Ok(None);
    };
    if s.chars().nth(MAX_HEADER_CHARS).is_some() {
        return Err(ParseError::HeaderTooLong);
    }
    if s.chars().any(|c| c != '\t' && c.is_control()) {
        return Err(ParseError::InvalidHeader);
    }
    Ok(Some(s))
}

fn parse_sender(raw: &str) -> Option<(Address, Name)> {
    let (user, raw_domain) = raw.rsplit_once('@')?;
    let domain = idna::domain_to_ascii_cow(raw_domain.as_bytes(), AsciiDenyList::STD3).ok()?;

    if !psl::domain(domain.as_bytes()).is_some_and(|d| d.suffix().is_known())
        || dispocheck::is_disposable_domain(&domain)
    {
        return None;
    }

    let mut fqdn = Name::from_ascii(&domain).ok()?;
    fqdn.set_fqdn(true);
    Some((Address::new(user, domain).ok()?, fqdn))
}

fn has_routable_mx(mx: &Lookup) -> bool {
    mx.answers()
        .iter()
        .any(|r| matches!(&r.data, RData::MX(m) if !m.exchange.is_root()))
}

fn build_message(reply_to: Mailbox, subject: String, body: String, config: &Config) -> Message {
    Message::builder()
        .from(Mailbox::new(
            reply_to.name.clone(),
            config.from_address.clone(),
        ))
        .reply_to(reply_to)
        .to(config.to_mailbox.clone())
        .subject(subject)
        .singlepart(SinglePart::plain(body))
        .expect("From and To are single valid Mailboxes")
}

#[derive(Debug)]
pub(super) struct Submission {
    reply_to: Mailbox,
    fqdn: Name,
    subject: String,
    body: String,
}

impl Submission {
    pub(super) fn parse(data: &[u8]) -> Result<Self, ParseError> {
        let msg = MessageParser::new()
            .parse(data)
            .ok_or(ParseError::MissingBody)?;

        let mut from = msg.headers().all(HeaderName::From).map(|h| h.value());
        let list = match (from.next(), from.next()) {
            (None, _) => return Err(ParseError::MissingFrom),
            (Some(HeaderValue::Address(list)), None) => list,
            _ => return Err(ParseError::InvalidEmail),
        };
        let mut addrs = list.iter();
        let (Some(ParsedAddress::Mailbox(mb)), None) = (addrs.next(), addrs.next()) else {
            return Err(ParseError::InvalidEmail);
        };

        let name = parse_header(mb.name())?.map(str::to_owned);
        let (address, fqdn) = mb
            .address()
            .and_then(parse_sender)
            .ok_or(ParseError::InvalidEmail)?;
        let subject = parse_header(msg.subject())?.map_or_else(
            || DEFAULT_SUBJECT.to_owned(),
            |s| format!("{DEFAULT_SUBJECT}: {s}"),
        );
        let body = msg
            .body_text(0)
            .filter(|b| !b.trim().is_empty())
            .ok_or(ParseError::MissingBody)?;
        if body.len() > MAX_MESSAGE_BODY_BYTES {
            return Err(ParseError::BodyTooLong);
        }

        Ok(Self {
            reply_to: Mailbox::new(name, address),
            fqdn,
            subject,
            body: body.into_owned(),
        })
    }

    pub(super) async fn verify_dns(
        self,
        resolver: &TokioResolver,
        config: &Config,
    ) -> Result<Message, Error> {
        let Self {
            reply_to,
            fqdn,
            subject,
            body,
        } = self;
        match resolver.mx_lookup(fqdn).await {
            Ok(mx) if has_routable_mx(&mx) => Ok(build_message(reply_to, subject, body, config)),
            Ok(_) => Err(ParseError::InvalidEmail.into()),
            Err(e) if e.is_no_records_found() => Err(ParseError::InvalidEmail.into()),
            Err(e) => {
                tracing::warn!(error = %e, "sender domain DNS verification failed");
                Err(Error::Dns(e))
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use hickory_resolver::proto::{
        op::Query,
        rr::{RecordType, rdata::MX},
    };
    use lettre::message::{Mailboxes, header};

    use super::*;

    #[test]
    fn parses_standard_and_mime_encoded_messages() {
        let raw = "From: =?UTF-8?Q?Sebasti=C3=A1n?= <JANE@B\u{00dc}CHER.DE>\r\n\
                   Subject: Hello\r\n\tWorld!\r\n\
                   MIME-Version: 1.0\r\n\
                   Content-Type: text/plain; charset=utf-8\r\n\
                   Content-Transfer-Encoding: quoted-printable\r\n\
                   \r\n\
                   Caf=C3=A9=20message\r\n";
        let parsed = Submission::parse(raw.as_bytes()).unwrap();
        assert_eq!(parsed.reply_to.name.as_deref(), Some("Sebastián"));
        assert_eq!(parsed.reply_to.email.domain(), "xn--bcher-kva.de");
        assert_eq!(parsed.subject, "Website Message: Hello World!");
        assert_eq!(parsed.body.trim_end(), "Café message");

        let email = build_message(
            parsed.reply_to,
            parsed.subject,
            parsed.body,
            &Config::default(),
        );
        let reply_to = Mailboxes::from(email.headers().get::<header::ReplyTo>().unwrap())
            .into_single()
            .unwrap();
        assert_eq!(reply_to.name.as_deref(), Some("Sebastián"));
        assert_eq!(reply_to.email.domain(), "xn--bcher-kva.de");

        let template = Submission::parse(include_bytes!("../../home/contact/message.eml")).unwrap();
        assert_eq!(template.reply_to.email.to_string(), "you@example.com");
        assert_eq!(template.subject, "Website Message");
    }

    #[test]
    fn rejects_invalid_submissions() {
        use ParseError::*;

        for sender in [
            "bot@10minutemail.com",
            "bot@sub.mailinator.com",
            "you@CO.UK",
            "you@localhost",
            "you@foo.invalid",
            "you@foo_bar.google.com",
            "you@[127.0.0.1]",
        ] {
            let msg = format!("From: <{sender}>\n\nHello!\n");
            assert_eq!(Submission::parse(msg.as_bytes()).unwrap_err(), InvalidEmail);
        }

        for raw in [
            "From: not-an-email\r\n\r\nHi\r\n",
            "From: <a@google.com>\r\nFrom: <b@google.com>\r\n\r\nHi\r\n",
            "From: <a@google.com>, <b@google.com>\r\n\r\nHi\r\n",
        ] {
            assert_eq!(Submission::parse(raw.as_bytes()).unwrap_err(), InvalidEmail);
        }
        for raw in [
            "From: =?UTF-8?Q?Jane=00Doe?= <jane@google.com>\r\n\r\nHi\r\n",
            "From: <jane@google.com>\r\nSubject: =?UTF-8?Q?Hi=1B?=\r\n\r\nHi\r\n",
        ] {
            assert_eq!(
                Submission::parse(raw.as_bytes()).unwrap_err(),
                InvalidHeader
            );
        }

        let long_hdr = "a".repeat(MAX_HEADER_CHARS + 1);
        for raw in [
            format!("From: {long_hdr} <jane@google.com>\n\nHi\n"),
            format!("From: <jane@google.com>\nSubject: {long_hdr}\n\nHi\n"),
        ] {
            assert_eq!(
                Submission::parse(raw.as_bytes()).unwrap_err(),
                HeaderTooLong
            );
        }

        let long_body = format!(
            "From: <jane@google.com>\n\n{}",
            "a".repeat(MAX_MESSAGE_BODY_BYTES + 1)
        );
        assert_eq!(
            Submission::parse(b"Date: Sun, 22 Nov 2026 12:00:00 +0000\r\n\r\nBody\r\n")
                .unwrap_err(),
            MissingFrom
        );
        assert_eq!(
            Submission::parse(b"From: Jane <jane@google.com>\n\n   \n").unwrap_err(),
            MissingBody
        );
        assert_eq!(
            Submission::parse(long_body.as_bytes()).unwrap_err(),
            BodyTooLong
        );
    }

    #[test]
    fn rejects_null_mx_and_accepts_routable_mx() {
        let query = Query::query("example.com.".parse().unwrap(), RecordType::MX);
        let null_mx = Lookup::from_rdata(query.clone(), RData::MX(MX::new(0, Name::root())));
        assert!(!has_routable_mx(&null_mx));

        let real_mx = Lookup::from_rdata(
            query,
            RData::MX(MX::new(10, "mx.google.com.".parse().unwrap())),
        );
        assert!(has_routable_mx(&real_mx));
    }
}
