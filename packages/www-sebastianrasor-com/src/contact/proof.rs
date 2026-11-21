use std::{str::FromStr, time::Duration};

use axum::{
    extract::{FromRef, FromRequestParts},
    http::{HeaderMap, request::Parts},
};
use fernet::Fernet;
use moka::sync::Cache;
use sha2::{Digest, Sha256};

use super::{ContactError, rate_limit::ClientSubnet};

const CHALLENGE_TTL: Duration = Duration::from_mins(15);
const MAX_SPENT_CHALLENGES: u64 = 4096;
const POW_DIFFICULTY_BITS: u32 = 20;
const CHALLENGE_HEADER: &str = "x-challenge";
const PROOF_HEADER: &str = "x-proof";

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct Nonce(u128);

impl FromStr for Nonce {
    type Err = ContactError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        if (s.len() > 1 && s.starts_with('0')) || !s.bytes().all(|b| b.is_ascii_digit()) {
            return Err(ContactError::InvalidChallenge);
        }
        s.parse::<u128>()
            .map(Self)
            .map_err(|_| ContactError::InvalidChallenge)
    }
}

impl Nonce {
    fn satisfies(self, challenge: &str) -> bool {
        let mut buf = itoa::Buffer::new();
        let mut hasher = Sha256::new();
        hasher.update(challenge.as_bytes());
        hasher.update(b":");
        hasher.update(buf.format(self.0).as_bytes());
        let digest = hasher.finalize();
        let first_word = u32::from_be_bytes([digest[0], digest[1], digest[2], digest[3]]);
        first_word.leading_zeros() >= POW_DIFFICULTY_BITS
    }
}

#[derive(Clone)]
pub(super) struct Challenger {
    fernet: Fernet,
    spent: Cache<[u8; 32], ()>,
}

impl Challenger {
    pub(super) fn new() -> Self {
        Self {
            fernet: Fernet::new(&Fernet::generate_key()).expect("generated key is always valid"),
            spent: Cache::builder()
                .max_capacity(MAX_SPENT_CHALLENGES)
                .time_to_live(CHALLENGE_TTL)
                .build(),
        }
    }

    pub(super) fn issue(&self, subnet: ClientSubnet) -> String {
        self.fernet.encrypt(subnet.to_string().as_bytes())
    }

    fn verify(
        &self,
        subnet: ClientSubnet,
        challenge: &str,
        proof: &str,
    ) -> Result<VerifiedProof, ContactError> {
        let nonce: Nonce = proof.parse()?;
        if !nonce.satisfies(challenge) {
            return Err(ContactError::InvalidChallenge);
        }

        let decrypted = self
            .fernet
            .decrypt_with_ttl(challenge, CHALLENGE_TTL.as_secs())
            .map_err(|_| ContactError::InvalidChallenge)?;
        if decrypted != subnet.to_string().as_bytes() {
            return Err(ContactError::InvalidChallenge);
        }

        let token_id: [u8; 32] = Sha256::digest(challenge.as_bytes()).into();
        if !self.spent.entry(token_id).or_insert(()).is_fresh() {
            return Err(ContactError::InvalidChallenge);
        }
        Ok(VerifiedProof(subnet))
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(super) struct VerifiedProof(ClientSubnet);

impl VerifiedProof {
    pub(super) const fn subnet(self) -> ClientSubnet {
        self.0
    }
}

impl<S> FromRequestParts<S> for VerifiedProof
where
    S: Send + Sync,
    Challenger: FromRef<S>,
{
    type Rejection = ContactError;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let subnet = ClientSubnet::from_request_parts(parts, state).await?;
        let challenge = header_str(&parts.headers, CHALLENGE_HEADER)?;
        let proof = header_str(&parts.headers, PROOF_HEADER)?;

        Challenger::from_ref(state).verify(subnet, challenge, proof)
    }
}

fn header_str<'a>(headers: &'a HeaderMap, name: &str) -> Result<&'a str, ContactError> {
    headers
        .get(name)
        .and_then(|value| value.to_str().ok())
        .ok_or(ContactError::InvalidChallenge)
}

#[cfg(test)]
mod tests {
    use std::net::{IpAddr, Ipv4Addr};

    use super::*;

    #[test]
    fn verifies_pow_subnet_binding_and_replay_protection() {
        let challenger = Challenger::new();
        let subnet_a = ClientSubnet::from(IpAddr::V4(Ipv4Addr::new(198, 51, 100, 7)));
        let subnet_b = ClientSubnet::from(IpAddr::V4(Ipv4Addr::new(203, 0, 113, 9)));

        let challenge = challenger.issue(subnet_a);
        let valid_nonce = (0_u128..=u128::MAX)
            .map(Nonce)
            .find(|nonce| nonce.satisfies(&challenge))
            .unwrap();
        let proof = valid_nonce.0.to_string();

        assert!("007".parse::<Nonce>().is_err());
        assert!("not-digits".parse::<Nonce>().is_err());
        assert!(!valid_nonce.satisfies("different-challenge"));

        assert!(matches!(
            challenger.verify(subnet_b, &challenge, &proof),
            Err(ContactError::InvalidChallenge)
        ));
        assert_eq!(
            challenger.verify(subnet_a, &challenge, &proof).unwrap(),
            VerifiedProof(subnet_a)
        );
        assert!(matches!(
            challenger.verify(subnet_a, &challenge, &proof),
            Err(ContactError::InvalidChallenge)
        ));
    }
}
