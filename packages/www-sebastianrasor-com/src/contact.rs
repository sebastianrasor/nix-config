use std::{
    collections::VecDeque,
    error::Error,
    net::{IpAddr, Ipv6Addr, SocketAddr},
    sync::{Arc, Mutex},
    time::{Duration, Instant},
};

use axum::{
    Json, Router,
    extract::{ConnectInfo, DefaultBodyLimit, State, rejection::JsonRejection},
    http::{HeaderMap, Method, Request, StatusCode, header},
    response::{IntoResponse, NoContent, Response},
    routing::post,
};
use check_if_email_exists::{
    CheckEmailInput, Reachable, check_email,
    smtp::{SmtpError, verif_method::VerifMethod},
};
use fernet::Fernet;
use lettre::{
    Address, AsyncSmtpTransport, AsyncTransport, Message, Tokio1Executor,
    message::{Mailbox, header::ContentType},
};
use moka::sync::Cache;
use problem_details::ProblemDetails;
use serde::Deserialize;
use sha2::{Digest, Sha256};
use tokio::sync::Semaphore;
use tower_governor::{
    GovernorError, GovernorLayer, governor::GovernorConfigBuilder, key_extractor::KeyExtractor,
};

const DELIVERABILITY_CHECK_TIMEOUT: Duration = Duration::from_secs(10);
const CHALLENGE_TTL: Duration = Duration::from_hours(1);
const GET_RATE_LIMIT_PERIOD: Duration = Duration::from_secs(10);
const GET_RATE_LIMIT_BURST: u32 = 6;
const POST_RATE_LIMIT_PERIOD: Duration = Duration::from_mins(10);
const POST_RATE_LIMIT_BURST: u32 = 2;
const GLOBAL_SEND_WINDOW: Duration = Duration::from_hours(1);
const GLOBAL_SEND_LIMIT: usize = 15;
const MAX_CONCURRENT_VERIFICATIONS: usize = 4;
const MAX_BODY_LIMIT_BYTES: usize = 64 * 1024;
const MAX_MESSAGE_BODY_BYTES: usize = 32 * 1024;
const MAX_SUBJECT_CHARS: usize = 200;
const POW_DIFFICULTY_BITS: u32 = 20;

const CHALLENGE_HEADER: &str = "x-challenge";
const PROOF_HEADER: &str = "x-proof";
const REAL_IP_HEADER: &str = "x-real-ip";
const DEFAULT_SUBJECT: &str = "Website Message";

#[derive(Deserialize)]
#[cfg_attr(debug_assertions, serde(default))]
pub struct Config {
    #[serde(default = "default_from_address")]
    from_address: Address,
    smtp_connection_url: String,
    to_mailbox: Mailbox,
    #[serde(skip, default = "default_skip_deliverability")]
    skip_deliverability_check: bool,
}

fn default_from_address() -> Address {
    Address::new_dangerous("noreply", "www.sebastianrasor.com")
}

const fn default_skip_deliverability() -> bool {
    cfg!(debug_assertions)
}

#[cfg(debug_assertions)]
impl Default for Config {
    fn default() -> Self {
        Self {
            from_address: default_from_address(),
            smtp_connection_url: "smtp://noreply:password1@localhost:1025".to_string(),
            to_mailbox: Mailbox::new(
                Some("Sebastian Rasor".to_string()),
                Address::new_dangerous("sebastian", "test"),
            ),
            skip_deliverability_check: true,
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct ClientSubnetExtractor;

impl KeyExtractor for ClientSubnetExtractor {
    type Key = IpAddr;

    fn extract<T>(&self, req: &Request<T>) -> Result<Self::Key, GovernorError> {
        let peer_ip = req
            .extensions()
            .get::<ConnectInfo<SocketAddr>>()
            .map(|ConnectInfo(addr)| addr.ip());
        extract_client_subnet(req.headers(), peer_ip).ok_or(GovernorError::UnableToExtractKey)
    }
}

struct GlobalQuota {
    recent: Mutex<VecDeque<Instant>>,
}

impl GlobalQuota {
    const fn new() -> Self {
        Self {
            recent: Mutex::new(VecDeque::new()),
        }
    }

    fn acquire(&self) -> Result<(), ContactError> {
        let now = Instant::now();
        let mut recent = self
            .recent
            .lock()
            .unwrap_or_else(std::sync::PoisonError::into_inner);
        while recent
            .front()
            .is_some_and(|&ts| now.duration_since(ts) >= GLOBAL_SEND_WINDOW)
        {
            recent.pop_front();
        }
        if recent.len() >= GLOBAL_SEND_LIMIT {
            return Err(ContactError::RateLimited);
        }
        recent.push_back(now);
        drop(recent);
        Ok(())
    }
}

struct AppState {
    from_address: Address,
    to_mailbox: Mailbox,
    skip_deliverability_check: bool,
    verif_method: VerifMethod,
    verify_semaphore: Semaphore,
    global_quota: GlobalQuota,
    sender: AsyncSmtpTransport<Tokio1Executor>,
    fernet: Fernet,
    spent_challenges: Cache<String, ()>,
}

#[derive(Deserialize)]
struct Submission {
    mail_from: Option<String>,
    data: String,
}

#[derive(Debug, thiserror::Error)]
enum ContactError {
    #[error("Mail challenge expired or invalid. Please try sending again.")]
    InvalidChallenge,
    #[error("Too many messages received recently. Please try again later.")]
    RateLimited,
    #[error(transparent)]
    Json(#[from] JsonRejection),
    #[error("The {0} is required.")]
    MissingField(&'static str),
    #[error("The {0} exceeds the maximum allowed length.")]
    FieldTooLong(&'static str),
    #[error("Invalid sender email address.")]
    InvalidEmail,
    #[error(transparent)]
    Smtp(#[from] lettre::transport::smtp::Error),
    #[error(transparent)]
    SmtpVerification(#[from] SmtpError),
    #[error(transparent)]
    VerificationTimeout(#[from] tokio::time::error::Elapsed),
}

impl IntoResponse for ContactError {
    fn into_response(self) -> Response {
        let (status, detail) = match self {
            Self::InvalidChallenge => (StatusCode::FORBIDDEN, self.to_string()),
            Self::RateLimited => (StatusCode::TOO_MANY_REQUESTS, self.to_string()),
            Self::Json(rejection) => (rejection.status(), rejection.body_text()),
            Self::MissingField(_) | Self::FieldTooLong(_) | Self::InvalidEmail => {
                (StatusCode::UNPROCESSABLE_ENTITY, self.to_string())
            }
            Self::Smtp(_) | Self::SmtpVerification(_) | Self::VerificationTimeout(_) => {
                tracing::error!(error = %self, "failed to process mail submission");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "The server was unable to complete your request. Please try again later."
                        .to_string(),
                )
            }
        };

        ProblemDetails::from_status_code(status)
            .with_detail(detail)
            .into_response()
    }
}

pub fn app(config: Config) -> Result<Router, Box<dyn Error>> {
    let sender =
        AsyncSmtpTransport::<Tokio1Executor>::from_url(&config.smtp_connection_url)?.build();
    let verif_method = VerifMethod::new_with_same_config_for_all(
        None,
        "www.sebastianrasor.com".to_string(),
        config.from_address.to_string(),
        lettre::transport::smtp::SMTP_PORT,
        Some(DELIVERABILITY_CHECK_TIMEOUT),
        0,
    );
    let get_governor = GovernorConfigBuilder::default()
        .period(GET_RATE_LIMIT_PERIOD)
        .burst_size(GET_RATE_LIMIT_BURST)
        .methods(vec![Method::GET])
        .key_extractor(ClientSubnetExtractor)
        .finish()
        .expect("GET governor config is always valid");
    let post_governor = GovernorConfigBuilder::default()
        .period(POST_RATE_LIMIT_PERIOD)
        .burst_size(POST_RATE_LIMIT_BURST)
        .methods(vec![Method::POST])
        .key_extractor(ClientSubnetExtractor)
        .finish()
        .expect("POST governor config is always valid");
    let state = Arc::new(AppState {
        from_address: config.from_address,
        to_mailbox: config.to_mailbox,
        skip_deliverability_check: config.skip_deliverability_check,
        verif_method,
        verify_semaphore: Semaphore::new(MAX_CONCURRENT_VERIFICATIONS),
        global_quota: GlobalQuota::new(),
        sender,
        fernet: Fernet::new(&Fernet::generate_key()).expect("generated key is always valid"),
        spent_challenges: Cache::builder().time_to_live(CHALLENGE_TTL).build(),
    });

    Ok(Router::new()
        .route(
            "/contact",
            post(submit).get(issue_challenge).with_state(state),
        )
        .layer(DefaultBodyLimit::max(MAX_BODY_LIMIT_BYTES))
        .layer(GovernorLayer::new(get_governor))
        .layer(GovernorLayer::new(post_governor)))
}

async fn issue_challenge(
    State(state): State<Arc<AppState>>,
    ConnectInfo(peer): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
) -> Result<impl IntoResponse, ContactError> {
    let subnet =
        extract_client_subnet(&headers, Some(peer.ip())).ok_or(ContactError::InvalidChallenge)?;
    Ok((
        [(header::CACHE_CONTROL, "no-store")],
        state.fernet.encrypt(subnet.to_string().as_bytes()),
    ))
}

async fn submit(
    State(state): State<Arc<AppState>>,
    ConnectInfo(peer): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
    payload: Result<Json<Submission>, JsonRejection>,
) -> Result<NoContent, ContactError> {
    let subnet =
        extract_client_subnet(&headers, Some(peer.ip())).ok_or(ContactError::InvalidChallenge)?;
    let challenge = headers
        .get(CHALLENGE_HEADER)
        .and_then(|value| value.to_str().ok())
        .ok_or(ContactError::InvalidChallenge)?;
    let proof = headers
        .get(PROOF_HEADER)
        .and_then(|value| value.to_str().ok())
        .ok_or(ContactError::InvalidChallenge)?;

    let decrypted = state
        .fernet
        .decrypt_with_ttl(challenge, CHALLENGE_TTL.as_secs())
        .map_err(|_| ContactError::InvalidChallenge)?;
    if decrypted != subnet.to_string().as_bytes() || !verify_pow(challenge, proof) {
        return Err(ContactError::InvalidChallenge);
    }

    if !state
        .spent_challenges
        .entry_by_ref(challenge)
        .or_insert(())
        .is_fresh()
    {
        return Err(ContactError::InvalidChallenge);
    }

    let Json(submission) = payload?;
    let (sender, subject, body) = parse_rfc5322(&submission.data, submission.mail_from.as_deref())?;

    state.global_quota.acquire()?;

    if !state.skip_deliverability_check {
        let _permit = state
            .verify_semaphore
            .acquire()
            .await
            .expect("verification semaphore is never closed");
        let deliverability_check = CheckEmailInput {
            to_email: sender.email.to_string(),
            verif_method: state.verif_method.clone(),
            ..Default::default()
        };
        let output = tokio::time::timeout(
            DELIVERABILITY_CHECK_TIMEOUT,
            check_email(&deliverability_check),
        )
        .await?;

        if matches!(output.is_reachable, Reachable::Invalid)
            || output.misc.as_ref().is_ok_and(|misc| misc.is_disposable)
            || !output.smtp?.is_deliverable
        {
            return Err(ContactError::InvalidEmail);
        }
    }

    let message = Message::builder()
        .from(Mailbox::new(
            sender.name.clone(),
            state.from_address.clone(),
        ))
        .reply_to(sender)
        .to(state.to_mailbox.clone())
        .subject(subject)
        .header(ContentType::TEXT_PLAIN)
        .body(body)
        .expect("from and to are always set");

    state.sender.send(message).await?;

    Ok(NoContent)
}

const fn normalize_subnet(ip: IpAddr) -> IpAddr {
    match ip {
        IpAddr::V4(v4) => IpAddr::V4(v4),
        IpAddr::V6(v6) => {
            if let Some(mapped) = v6.to_ipv4_mapped() {
                IpAddr::V4(mapped)
            } else {
                IpAddr::V6(Ipv6Addr::from_bits(v6.to_bits() & (!0_u128 << 64)))
            }
        }
    }
}

fn extract_client_subnet(headers: &HeaderMap, peer_ip: Option<IpAddr>) -> Option<IpAddr> {
    let real_ip = if peer_ip.is_some_and(|ip| ip.is_loopback()) {
        headers
            .get(REAL_IP_HEADER)
            .and_then(|hv| hv.to_str().ok())
            .and_then(|s| s.trim().parse::<IpAddr>().ok())
            .or(peer_ip)
    } else {
        peer_ip
    };
    real_ip.map(normalize_subnet)
}

fn verify_pow(challenge: &str, proof: &str) -> bool {
    if proof.is_empty() || proof.len() > 32 || !proof.bytes().all(|b| b.is_ascii_digit()) {
        return false;
    }
    let mut hasher = Sha256::new();
    hasher.update(challenge.as_bytes());
    hasher.update(b":");
    hasher.update(proof.as_bytes());
    let digest = hasher.finalize();
    let first_word = u32::from_be_bytes([digest[0], digest[1], digest[2], digest[3]]);
    first_word.leading_zeros() >= POW_DIFFICULTY_BITS
}

fn split_headers_and_body(normalized: &str) -> (&str, &str) {
    if let Some(rest) = normalized.strip_prefix('\n') {
        return ("", rest);
    }
    if let Some(pair) = normalized.split_once("\n\n") {
        return pair;
    }
    if normalized
        .lines()
        .all(|line| line.contains(':') || line.starts_with([' ', '\t']))
    {
        (normalized, "")
    } else {
        ("", normalized)
    }
}

fn parse_rfc5322(
    data: &str,
    envelope_from: Option<&str>,
) -> Result<(Mailbox, String, String), ContactError> {
    let normalized = data.replace("\r\n", "\n");
    let (raw_headers, body) = split_headers_and_body(&normalized);

    let mut headers: Vec<String> = Vec::new();
    for line in raw_headers.lines() {
        if line.starts_with([' ', '\t']) {
            if let Some(last) = headers.last_mut() {
                last.push(' ');
                last.push_str(line.trim());
            }
        } else {
            headers.push(line.to_string());
        }
    }

    let mut from_header = None;
    let mut subject_header = None;
    for header in &headers {
        if let Some((name, value)) = header.split_once(':') {
            let value = value.trim();
            if name.eq_ignore_ascii_case("from") && !value.is_empty() {
                from_header = Some(value);
            } else if name.eq_ignore_ascii_case("subject") && !value.is_empty() {
                subject_header = Some(value);
            }
        }
    }

    let from_raw = from_header
        .or_else(|| {
            envelope_from
                .map(str::trim)
                .filter(|addr| !addr.is_empty() && !addr.eq_ignore_ascii_case("root@www"))
        })
        .ok_or(ContactError::MissingField("From header"))?;

    let sender: Mailbox = from_raw.parse().map_err(|_| ContactError::InvalidEmail)?;
    let email_str = sender.email.to_string();
    if let Some((_, domain)) = email_str.rsplit_once('@')
        && (domain.eq_ignore_ascii_case("example.com")
            || domain.eq_ignore_ascii_case("example.org")
            || domain.eq_ignore_ascii_case("example.net")
            || domain.eq_ignore_ascii_case("localhost"))
    {
        return Err(ContactError::InvalidEmail);
    }

    if let Some(subj) = subject_header
        && subj.chars().count() > MAX_SUBJECT_CHARS
    {
        return Err(ContactError::FieldTooLong("Subject header"));
    }

    if body.trim().is_empty() {
        return Err(ContactError::MissingField("message body"));
    }
    if body.len() > MAX_MESSAGE_BODY_BYTES {
        return Err(ContactError::FieldTooLong("message body"));
    }

    let subject = subject_header.map_or_else(
        || DEFAULT_SUBJECT.to_string(),
        |s| format!("{DEFAULT_SUBJECT}: {s}"),
    );

    Ok((sender, subject, body.to_string()))
}

#[cfg(test)]
mod tests {
    use std::net::Ipv4Addr;

    use super::*;

    #[test]
    fn parses_standard_rfc5322_message() {
        let raw = "To: sebastian@www.sebastianrasor.com\r\n\
                   From: Jane Doe <jane@google.com>\r\n\
                   Subject: Howdy\r\n\
                   \r\n\
                   Hello from WASM Linux!\n";
        let (sender, subject, body) = parse_rfc5322(raw, Some("root@www")).unwrap();
        assert_eq!(sender.name.as_deref(), Some("Jane Doe"));
        assert_eq!(sender.email.to_string(), "jane@google.com");
        assert_eq!(subject, "Website Message: Howdy");
        assert_eq!(body, "Hello from WASM Linux!\n");
    }

    #[test]
    fn rejects_placeholder_example_domain_and_empty_body() {
        let unedited = "To: sebastian@www.sebastianrasor.com\n\
                        From: Your Name <you@example.com>\n\n";
        assert!(matches!(
            parse_rfc5322(unedited, Some("root@www")),
            Err(ContactError::InvalidEmail)
        ));

        let empty_body = "From: Jane <jane@google.com>\n\n   \n";
        assert!(matches!(
            parse_rfc5322(empty_body, Some("root@www")),
            Err(ContactError::MissingField("message body"))
        ));
    }

    #[test]
    fn falls_back_to_envelope_sender_and_default_subject() {
        let raw = "\nJust a raw SMTP body.\n";
        let (sender, subject, body) = parse_rfc5322(raw, Some("jane@google.com")).unwrap();
        assert_eq!(sender.email.to_string(), "jane@google.com");
        assert_eq!(subject, DEFAULT_SUBJECT);
        assert_eq!(body, "Just a raw SMTP body.\n");
    }

    #[test]
    fn normalizes_ipv6_to_64_and_ignores_spoofed_headers() {
        let mut headers = HeaderMap::new();
        headers.insert("x-forwarded-for", "1.2.3.4".parse().unwrap());
        headers.insert("x-real-ip", "2001:db8:abcd:1234:5678::1".parse().unwrap());

        // Non-loopback peer ignores X-Real-IP completely
        let external_peer = Some(IpAddr::V4(Ipv4Addr::new(198, 51, 100, 7)));
        assert_eq!(
            extract_client_subnet(&headers, external_peer),
            external_peer
        );

        // Loopback peer trusts X-Real-IP (not X-Forwarded-For) and masks IPv6 to /64
        let loopback_peer = Some(IpAddr::V4(Ipv4Addr::LOCALHOST));
        assert_eq!(
            extract_client_subnet(&headers, loopback_peer),
            Some("2001:db8:abcd:1234::".parse().unwrap())
        );
    }

    #[test]
    fn verifies_pow_accurately() {
        let challenge = "sample-challenge";
        let mut nonce = 0_u64;
        let valid_proof = loop {
            let candidate = nonce.to_string();
            if verify_pow(challenge, &candidate) {
                break candidate;
            }
            nonce += 1;
        };
        assert!(verify_pow(challenge, &valid_proof));
        assert!(!verify_pow("different-challenge", &valid_proof));
        assert!(!verify_pow(challenge, "not-digits"));
    }
}
