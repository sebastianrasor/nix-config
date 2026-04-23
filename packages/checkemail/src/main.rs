use axum::{
    extract::{Path, Request, State},
    http::{HeaderMap, StatusCode},
    middleware::{self, Next},
    response::Response,
    routing::get,
    Router,
};
use color_eyre::eyre::{ContextCompat, Result};
use lettre::{
    transport::smtp::{
        client::SmtpConnection,
        commands::{Mail, Quit, Rcpt},
        extension::ClientId,
        SMTP_PORT,
    },
    Address,
};
use hickory_proto::rr::domain::IntoName;
use hickory_proto::rr::RData;
use hickory_resolver::Resolver;

const TOKEN_ENV_KEY: &str = "CHECKEMAIL_TOKEN";

async fn get_mx(domain: impl IntoName) -> Result<String> {
    let resolver = Resolver::builder_tokio()?.build()?;
    let mx_response = resolver.mx_lookup(domain).await?;
    mx_response.answers().iter().find_map(|record| match &record.data {
        RData::MX(mx) => Some(mx.exchange.to_string()),
        _ => None
    }).context("No available MX")
}

async fn check_email(email: lettre::Address) -> Result<bool> {
    let hello = ClientId::Domain("checkemail.rasor.us".to_owned());
    let mx = get_mx(email.domain()).await?;
    let mut client = SmtpConnection::connect(&(mx, SMTP_PORT), None, &hello, None, None)?;
    client.command(Mail::new(
        Some("noreply@checkemail.rasor.us".parse()?),
        vec![],
    ))?;
    let result = client.command(Rcpt::new(email, vec![]));
    client.command(Quit)?;
    let response = result?;
    Ok(response.code().is_positive())
}

async fn handler(Path(email): Path<String>) -> StatusCode {
    let Ok(address) = email.parse::<Address>() else {
        return StatusCode::NOT_FOUND;
    };

    let Ok(check_email_result) = check_email(address).await else {
        return StatusCode::NOT_FOUND;
    };

    if check_email_result {
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}

#[derive(Clone)]
struct AppState {
    api_token: String,
}

#[tokio::main]
async fn main() -> Result<()> {
    let state = AppState {
        api_token: env::var(TOKEN_ENV_KEY)?,
    };

    let app = Router::new()
        .route("/{email}", get(handler))
        .route_layer(middleware::from_fn_with_state(state, auth));

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000").await?;

    Ok(axum::serve(listener, app).await?)
}

async fn auth(
    State(state): State<AppState>,

    headers: HeaderMap,
    request: Request,
    next: Next,
) -> Result<Response, StatusCode> {
    match get_token(&headers) {
        Some(token) if token == format!("Bearer {}", state.api_token) => {
            let response = next.run(request).await;
            Ok(response)
        }
        _ => Err(StatusCode::UNAUTHORIZED),
    }
}

fn get_token(headers: &HeaderMap) -> Option<&str> {
    headers
        .get("Authorization")
        .and_then(|header| header.to_str().ok())
}
