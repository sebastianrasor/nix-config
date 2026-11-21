use std::{str::FromStr, sync::LazyLock, time::Duration};

use axum::{Json, body::Body, extract::FromRequest, http::Request};
use hickory_resolver::{Name, TokioAsyncResolver, error::ResolveErrorKind};
use lettre::{
    Address, Message,
    message::{Mailbox, header::ContentType},
};
use mail_parser::{HeaderForm, HeaderName, MessageParser};
use serde::Deserialize;

use super::{ContactError, Field};

const DNS_CHECK_TIMEOUT: Duration = Duration::from_secs(5);
const MAX_MESSAGE_BODY_BYTES: usize = 32 * 1024;
const MAX_SENDER_NAME_CHARS: usize = 100;
const MAX_SUBJECT_CHARS: usize = 200;
const DEFAULT_SUBJECT: &str = "Website Message";

static RESERVED_ZONES: LazyLock<[Name; 8]> = LazyLock::new(|| {
    [
        "example.",
        "example.com.",
        "example.net.",
        "example.org.",
        "invalid.",
        "local.",
        "localhost.",
        "test.",
    ]
    .map(|zone| Name::from_ascii(zone).expect("reserved zones are valid ASCII FQDNs"))
});

static PARSER: LazyLock<MessageParser> = LazyLock::new(|| {
    MessageParser::new()
        .unknown_headers(HeaderForm::Ignore)
        .max_depth(4)
        .max_parts(8)
        .max_encoded_nesting(0)
});

#[derive(Clone, Debug)]
pub(super) struct MailDomain(Name);

impl FromStr for MailDomain {
    type Err = ContactError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let mut fqdn = Name::from_ascii(s).map_err(|_| ContactError::InvalidEmail)?;
        fqdn.set_fqdn(true);
        if fqdn.is_root() || RESERVED_ZONES.iter().any(|zone| zone.zone_of(&fqdn)) {
            return Err(ContactError::InvalidEmail);
        }
        Ok(Self(fqdn))
    }
}

impl MailDomain {
    pub(super) async fn accepts_mail(
        &self,
        resolver: &TokioAsyncResolver,
    ) -> Result<bool, ContactError> {
        tokio::time::timeout(DNS_CHECK_TIMEOUT, self.lookup_mx(resolver)).await?
    }

    async fn lookup_mx(&self, resolver: &TokioAsyncResolver) -> Result<bool, ContactError> {
        let lookup = match resolver.mx_lookup(self.0.clone()).await {
            Ok(lookup) => lookup,
            Err(err) if matches!(err.kind(), ResolveErrorKind::NoRecordsFound { .. }) => {
                return Ok(false);
            }
            Err(err) => return Err(Box::new(err).into()),
        };

        for mx in lookup.iter().filter(|mx| !mx.exchange().is_root()) {
            match resolver.lookup_ip(mx.exchange().clone()).await {
                Ok(ips) if ips.iter().next().is_some() => return Ok(true),
                Ok(_) => {}
                Err(err) if matches!(err.kind(), ResolveErrorKind::NoRecordsFound { .. }) => {}
                Err(err) => return Err(Box::new(err).into()),
            }
        }

        Ok(false)
    }
}

#[derive(Debug)]
struct SenderMailbox {
    mailbox: Mailbox,
    domain: MailDomain,
}

impl SenderMailbox {
    fn from_parts(name: Option<&str>, raw_email: &str) -> Result<Self, ContactError> {
        let email: Address = raw_email
            .trim()
            .trim_start_matches('<')
            .trim_end_matches('>')
            .parse()
            .map_err(|_| ContactError::InvalidEmail)?;
        let domain: MailDomain = email.domain().parse()?;
        if !mailchecker::is_valid(email.as_ref()) {
            return Err(ContactError::InvalidEmail);
        }

        let clean_name = name.map(sanitize_header_text).filter(|n| !n.is_empty());
        if clean_name
            .as_deref()
            .is_some_and(|n| n.chars().count() > MAX_SENDER_NAME_CHARS)
        {
            return Err(ContactError::FieldTooLong(Field::FromName));
        }

        Ok(Self {
            mailbox: Mailbox::new(clean_name, email),
            domain,
        })
    }

    fn from_envelope(envelope_from: Option<&str>) -> Result<Self, ContactError> {
        let fallback = envelope_from
            .map(str::trim)
            .filter(|addr| !addr.is_empty() && !addr.eq_ignore_ascii_case("root@www"))
            .ok_or(ContactError::MissingField(Field::From))?;
        Self::from_parts(None, fallback)
    }
}

#[derive(Debug, Eq, PartialEq)]
struct Subject(String);

impl Subject {
    fn parse(raw: Option<&str>) -> Result<Self, ContactError> {
        let Some(clean) = raw.map(sanitize_header_text).filter(|s| !s.is_empty()) else {
            return Ok(Self(DEFAULT_SUBJECT.to_string()));
        };
        if clean.chars().count() > MAX_SUBJECT_CHARS {
            return Err(ContactError::FieldTooLong(Field::Subject));
        }
        Ok(Self(format!("{DEFAULT_SUBJECT}: {clean}")))
    }
}

#[derive(Debug, Eq, PartialEq)]
struct MessageBody(String);

impl TryFrom<&str> for MessageBody {
    type Error = ContactError;

    fn try_from(raw: &str) -> Result<Self, Self::Error> {
        let normalized = raw.replace("\r\n", "\n");
        if normalized.trim().is_empty() {
            return Err(ContactError::MissingField(Field::Body));
        }
        if normalized.len() > MAX_MESSAGE_BODY_BYTES {
            return Err(ContactError::FieldTooLong(Field::Body));
        }
        Ok(Self(normalized))
    }
}

#[derive(Deserialize)]
struct RawSubmission {
    mail_from: Option<String>,
    data: String,
}

#[derive(Debug)]
pub(super) struct ContactMessage {
    sender: SenderMailbox,
    subject: Subject,
    body: MessageBody,
}

impl ContactMessage {
    fn parse(data: &str, envelope_from: Option<&str>) -> Result<Self, ContactError> {
        let Some(parsed) = PARSER.parse(data) else {
            return Ok(Self {
                sender: SenderMailbox::from_envelope(envelope_from)?,
                subject: Subject::parse(None)?,
                body: MessageBody::try_from(data)?,
            });
        };

        let headers = parsed.headers();
        if headers.all(HeaderName::Subject).nth(1).is_some() {
            return Err(ContactError::DuplicateHeader(Field::Subject));
        }

        let mut from_headers = headers.all(HeaderName::From);
        let has_from = from_headers.next().is_some();
        if from_headers.next().is_some() {
            return Err(ContactError::DuplicateHeader(Field::From));
        }

        let sender = if has_from {
            let from = parsed
                .from()
                .filter(|list| !list.has_groups())
                .ok_or(ContactError::InvalidEmail)?;
            let mut mailboxes = from.mailboxes();
            let mailbox = mailboxes
                .next()
                .filter(|_| mailboxes.next().is_none())
                .ok_or(ContactError::InvalidEmail)?;
            let email = mailbox.address().ok_or(ContactError::InvalidEmail)?;
            SenderMailbox::from_parts(mailbox.name(), email)?
        } else {
            SenderMailbox::from_envelope(envelope_from)?
        };

        let body_raw = parsed.body_text(0).unwrap_or_default();

        Ok(Self {
            sender,
            subject: Subject::parse(parsed.subject())?,
            body: MessageBody::try_from(body_raw.as_ref())?,
        })
    }

    pub(super) const fn sender_domain(&self) -> &MailDomain {
        &self.sender.domain
    }

    pub(super) fn into_email(self, from_address: Address, to_mailbox: Mailbox) -> Message {
        let reply_to = self.sender.mailbox;
        Message::builder()
            .from(Mailbox::new(reply_to.name.clone(), from_address))
            .reply_to(reply_to)
            .to(to_mailbox)
            .subject(self.subject.0)
            .header(ContentType::TEXT_PLAIN)
            .body(self.body.0)
            .expect("from and to are always set")
    }
}

impl TryFrom<RawSubmission> for ContactMessage {
    type Error = ContactError;

    fn try_from(raw: RawSubmission) -> Result<Self, Self::Error> {
        Self::parse(&raw.data, raw.mail_from.as_deref())
    }
}

impl<S: Send + Sync> FromRequest<S> for ContactMessage {
    type Rejection = ContactError;

    async fn from_request(req: Request<Body>, state: &S) -> Result<Self, Self::Rejection> {
        let Json(raw) = Json::<RawSubmission>::from_request(req, state).await?;
        Self::try_from(raw)
    }
}

fn sanitize_header_text(input: &str) -> String {
    input
        .trim_matches(|c: char| c.is_whitespace() || c.is_control())
        .chars()
        .filter(|c| !c.is_control())
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_standard_rfc5322_message() {
        let raw = "To: sebastian@www.sebastianrasor.com\r\n\
                   From: Jane Doe <jane@google.com>\r\n\
                   Subject: Howdy\r\n\
                   \r\n\
                   Hello from WASM Linux!\n";
        let msg = ContactMessage::parse(raw, Some("root@www")).unwrap();
        assert_eq!(msg.sender.mailbox.name.as_deref(), Some("Jane Doe"));
        assert_eq!(msg.sender.mailbox.email.to_string(), "jane@google.com");
        assert_eq!(msg.subject, Subject("Website Message: Howdy".to_string()));
        assert_eq!(
            msg.body,
            MessageBody("Hello from WASM Linux!\n".to_string())
        );
    }

    #[test]
    fn decodes_rfc2047_headers_and_quoted_printable_body() {
        let raw = "From: =?UTF-8?Q?Sebasti=C3=A1n?= <jane@google.com>\r\n\
                   Subject: =?UTF-8?B?SGVsbG8gV29ybGQh?=\r\n\
                   MIME-Version: 1.0\r\n\
                   Content-Type: text/plain; charset=utf-8\r\n\
                   Content-Transfer-Encoding: quoted-printable\r\n\
                   \r\n\
                   Caf=C3=A9=20message\r\n";
        let msg = ContactMessage::parse(raw, None).unwrap();
        assert_eq!(msg.sender.mailbox.name.as_deref(), Some("Sebastián"));
        assert_eq!(
            msg.subject,
            Subject("Website Message: Hello World!".to_string())
        );
        assert_eq!(msg.body, MessageBody("Café message\n".to_string()));
    }

    #[test]
    fn rejects_placeholder_disposable_and_empty_body() {
        let unedited = "From: Your Name <you@example.com>\n\nHello!\n";
        assert!(matches!(
            ContactMessage::parse(unedited, Some("root@www")),
            Err(ContactError::InvalidEmail)
        ));

        let subdomain_reserved = "From: Your Name <you@sub.example.org>\n\nHello!\n";
        assert!(matches!(
            ContactMessage::parse(subdomain_reserved, Some("root@www")),
            Err(ContactError::InvalidEmail)
        ));

        let disposable = "From: Bot <bot@10minutemail.com>\n\nHello!\n";
        assert!(matches!(
            ContactMessage::parse(disposable, Some("root@www")),
            Err(ContactError::InvalidEmail)
        ));

        let empty_body = "From: Jane <jane@google.com>\n\n   \n";
        assert!(matches!(
            ContactMessage::parse(empty_body, Some("root@www")),
            Err(ContactError::MissingField(Field::Body))
        ));
    }

    #[test]
    fn rejects_duplicate_headers_and_oversized_display_name() {
        let dup_from = "From: a@google.com\nFrom: b@google.com\n\nHello!\n";
        assert!(matches!(
            ContactMessage::parse(dup_from, None),
            Err(ContactError::DuplicateHeader(Field::From))
        ));

        let long_name = format!("From: {} <jane@google.com>\n\nHello!\n", "A".repeat(101));
        assert!(matches!(
            ContactMessage::parse(&long_name, None),
            Err(ContactError::FieldTooLong(Field::FromName))
        ));

        let ctrl_name = "From: \"Jane\x07\x1bDoe\" <jane@google.com>\n\nHello!\n";
        let msg = ContactMessage::parse(ctrl_name, None).unwrap();
        assert_eq!(msg.sender.mailbox.name.as_deref(), Some("JaneDoe"));
    }

    #[test]
    fn falls_back_to_envelope_sender_and_default_subject() {
        for raw in ["\nJust a raw SMTP body.\n", "Just a raw SMTP body.\n"] {
            let msg = ContactMessage::parse(raw, Some("jane@google.com")).unwrap();
            assert_eq!(msg.sender.mailbox.email.to_string(), "jane@google.com");
            assert_eq!(msg.subject, Subject(DEFAULT_SUBJECT.to_string()));
            assert_eq!(msg.body, MessageBody("Just a raw SMTP body.\n".to_string()));
        }
    }
}
