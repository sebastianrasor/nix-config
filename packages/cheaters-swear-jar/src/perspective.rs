use std::collections::HashMap;

use anyhow::Result;
use serde::{Deserialize, Serialize};
use serde_with::skip_serializing_none;

#[skip_serializing_none]
#[derive(Serialize, Deserialize, Default)]
#[skip_serializing_none]
struct PerspectiveComment {
    text: String,
    #[serde(rename = "type")]
    type_: Option<String>,
}

#[skip_serializing_none]
#[derive(Serialize, Deserialize)]
struct PerspectiveContextComment {
    text: Option<String>,
    #[serde(rename = "type")]
    type_: Option<String>,
}

#[skip_serializing_none]
#[derive(Serialize, Deserialize)]
struct PerspectiveContext {
    entries: Option<Vec<PerspectiveContextComment>>,
}

#[skip_serializing_none]
#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
struct PerspectiveAttributeOptions {
    score_type: Option<String>,
    score_threshold: Option<f32>,
}

#[skip_serializing_none]
#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
struct AnalyzeCommentRequest {
    comment: PerspectiveComment,
    context: Option<PerspectiveContext>,
    requested_attributes: HashMap<String, PerspectiveAttributeOptions>,
    span_annotations: Option<bool>,
    languages: Option<Vec<String>>,
    do_not_store: Option<bool>,
    client_token: Option<String>,
    session_id: Option<String>,
    community_id: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PerspectiveScore {
    pub value: Option<f32>,
    #[serde(rename = "type")]
    pub type_: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PerspectiveSpanScore {
    pub begin: Option<usize>,
    pub end: Option<usize>,
    pub score: Option<PerspectiveScore>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PerspectiveAttributeScore {
    pub summary_score: Option<PerspectiveScore>,
    pub span_scores: Option<Vec<PerspectiveSpanScore>>,
    pub languages: Option<Vec<String>>,
    pub client_token: Option<String>,
}

#[derive(Serialize, Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct AnalyzeCommentResponse {
    pub attribute_scores: Option<HashMap<String, PerspectiveAttributeScore>>,
    pub languages: Option<Vec<String>>,
    pub client_token: Option<String>,
}

impl AnalyzeCommentResponse {
    pub fn unpack_score_value(&self, attribute_name: &str) -> Option<f32> {
        let Some(ref attribute_scores) = self.attribute_scores else {
            return None;
        };

        let Some(attribute_score) = attribute_scores.get(attribute_name) else {
            return None;
        };

        let Some(ref summary_score) = attribute_score.summary_score else {
            return None;
        };

        summary_score.value
    }
}

pub async fn analyze_comment(
    google_api_key: &str,
    comment: &str,
) -> Result<AnalyzeCommentResponse> {
    let perspective_comment = PerspectiveComment {
        text: comment.to_owned(),
        type_: None,
    };

    let requested_attributes = HashMap::from([(
        "PROFANITY".to_owned(),
        PerspectiveAttributeOptions::default(),
    )]);

    let analyze_comment_request = AnalyzeCommentRequest {
        comment: perspective_comment,
        requested_attributes,
        ..Default::default()
    };

    let client = reqwest::Client::new();
    let res = client
        .post(format!(
            "https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze?key={}",
            google_api_key
        ))
        .json(&analyze_comment_request)
        .send()
        .await?;

    let analyze_comment_response = res.json::<AnalyzeCommentResponse>().await?;

    Ok(analyze_comment_response)
}
