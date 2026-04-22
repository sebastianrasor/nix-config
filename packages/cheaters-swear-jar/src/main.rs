mod perspective;

use serenity::all::EmojiId;
use serenity::all::Timestamp;
use serenity::async_trait;
use serenity::cache::Settings as CacheSettings;
use serenity::model::channel::Message;
use serenity::model::gateway::Ready;
use serenity::prelude::*;
use std::collections::HashMap;
use std::fs;
use std::sync::Arc;
use tracing::{event, instrument, Level};

const GIFS: &str = include_str!("gifs");

struct SwearCounter;

impl TypeMapKey for SwearCounter {
    type Value = Arc<RwLock<HashMap<u64, u8>>>;
}

struct Bot {
    google_api_key: String,
}

#[async_trait]
impl EventHandler for Bot {
    #[instrument(skip(self))]
    async fn ready(&self, _ctx: Context, _ready: Ready) {
        event!(Level::INFO, "Bot is ready.");
    }

    #[instrument(skip_all, fields(author_username = msg.author.name, author_discriminator = msg.author.discriminator, msg_content = msg.content))]
    async fn message(&self, ctx: Context, msg: Message) {
        let Some(guild_id) = msg.guild_id else {
            event!(Level::INFO, ?msg.guild_id, "Message not from guild.");
            return;
        };
        if guild_id == 316738004335067139
            && !msg.content.is_empty()
            && GIFS
                .lines()
                .collect::<Vec<&str>>()
                .contains(&msg.content.as_str())
        {
            let react_result = msg.react(&ctx, EmojiId::new(1171493411270967447)).await;

            event!(
                Level::INFO,
                react_okay = react_result.is_ok(),
                "Reacted to message with anti SGA propaganda gif."
            );

            if let Err(error) = react_result {
                event!(Level::ERROR, ?error, "Failed to react to message.");
            }
        }
        if (include_str!("users")
            .lines()
            .flat_map(|x| x.parse())
            .collect::<Vec<u64>>())
        .contains(&msg.author.id.get())
        {
            let analyze_comment_result =
                perspective::analyze_comment(&self.google_api_key, &msg.content).await;
            let analyze_comment_response = match analyze_comment_result {
                Ok(response) => response,
                Err(error) => {
                    event!(Level::ERROR, ?error, "Perspective comment analysis failed.");
                    return;
                }
            };

            let score_option = analyze_comment_response.unpack_score_value("PROFANITY");
            let score = match score_option {
                Some(score) => score,
                None => {
                    event!(
                        Level::ERROR,
                        ?analyze_comment_response,
                        "Perspective response did not contain profanity score"
                    );
                    return;
                }
            };

            if score < 0.7 {
                event!(
                    Level::DEBUG,
                    profanity_score = score,
                    "Profanity score did not meet threshold."
                );
                return;
            }

            {
                let react_result = msg.react(&ctx, '‼').await;

                event!(
                    Level::INFO,
                    react_okay = react_result.is_ok(),
                    profanity_score = score,
                    "Reacted to message with profanity."
                );

                if let Err(error) = react_result {
                    event!(Level::ERROR, ?error, "Failed to react to message.");
                }
            }

            let counter_lock = {
                let data_read = ctx.data.read().await;

                data_read
                    .get::<SwearCounter>()
                    .expect("Expected SwearCounter in TypeMap.")
                    .clone()
            };

            let third_swear: bool;
            {
                let mut counter = counter_lock.write().await;

                let entry = counter.entry(msg.author.id.into()).or_insert(0);
                if *entry == 2 {
                    third_swear = true;
                    *entry = 0;
                } else {
                    third_swear = false;
                    *entry += 1;
                }
            }

            if third_swear {
                '_reply_block: {
                    let reply_result = msg
                        .reply(&ctx, "Stop swearing. You need a 5-minute timeout.")
                        .await;

                    event!(
                        Level::INFO,
                        reply_okay = reply_result.is_ok(),
                        "Replied to 3rd message with swear."
                    );

                    if let Err(error) = reply_result {
                        event!(Level::ERROR, ?error, "Failed to reply to message.");
                        return;
                    }
                }
                '_mute_block: {
                    let mut member = {
                        let result = msg.member(&ctx).await;
                        match result {
                            Ok(member) => member,
                            Err(error) => {
                                event!(Level::ERROR, ?error, "Error retrieving member.");
                                return;
                            }
                        }
                    };

                    let timeout_end_time = {
                        let timestamp_result =
                            Timestamp::from_unix_timestamp(msg.timestamp.unix_timestamp() + 300);
                        match timestamp_result {
                            Ok(timestamp) => timestamp,
                            Err(error) => {
                                event!(Level::ERROR, ?error, "Error creating timestamp.");
                                return;
                            }
                        }
                    };

                    let timeout_result = member
                        .disable_communication_until_datetime(&ctx, timeout_end_time)
                        .await;

                    event!(
                        Level::INFO,
                        react_okay = timeout_result.is_ok(),
                        "Timed out member for swearing too many times."
                    );

                    if let Err(error) = timeout_result {
                        event!(Level::ERROR, ?error, "Failed to timeout member.");
                    }
                }
            }
        }
    }
}

#[tokio::main]
async fn main() {
    let discord_token_path = env::var("DISCORD_TOKEN_PATH").expect("Expected a Discord token path in the environment");
    let discord_token = fs::read_to_string(discord_token_path).expect("Should be able to read Discord token");

    let google_api_key_path = env::var("GOOGLE_API_KEY_PATH").expect("Expected a Google API key in the environment");
    let google_api_key = fs::read_to_string(google_api_key_path).expect("Should be able to read Google API key");

    let intents = serenity::model::gateway::GatewayIntents::non_privileged()
        | serenity::model::gateway::GatewayIntents::MESSAGE_CONTENT;

    let mut cache_settings = CacheSettings::default();
    cache_settings.max_messages = 1000;

    let mut client = Client::builder(discord_token, intents)
        .event_handler(Bot { google_api_key })
        .cache_settings(cache_settings)
        .await
        .expect("Err creating client");

    {
        let mut data = client.data.write().await;
        data.insert::<SwearCounter>(Arc::new(RwLock::new(HashMap::default())));
    }

    // Start listening for events by starting a single shard
    if let Err(why) = client.start().await {
        println!("Client error: {why:?}");
    }
}
