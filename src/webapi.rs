use crate::*;
use anyhow::Result;
use chrono::{DateTime, Utc};
use std::{convert::Infallible, sync::Arc};
use warp::Filter;
use crate::{config::AppConfig, database::Database};


#[derive(Debug)]
pub struct WebApi {
    config: Arc<AppConfig>,
    database: Arc<Database>,
}


impl WebApi {
    pub fn new(config: Arc<AppConfig>, database: Arc<Database>) -> Self {
        WebApi {
            config,
            database,
        }
    }


    pub async fn start(self: Arc<Self>) -> Result<()> {
        let port = self.config.webapi_port;
        info!("Launching Small WebApi on http://127.0.0.1:{port}");

        let web_api = self.clone();
        let routes = warp::path::end()
            .and(warp::query::<std::collections::HashMap<String, String>>())
            .and_then(move |params| {
                let api = web_api.clone();
                async move { api.handle_request(params).await }
            })
            .or(warp::path::param().and_then(move |count: usize| {
                let api = self.clone();
                async move { api.handle_count_request(count).await }
            }));

        warp::serve(routes).run(([127, 0, 0, 1], port)).await;
        Ok(())
    }


    async fn handle_request(
        &self,
        _params: std::collections::HashMap<String, String>,
    ) -> Result<impl warp::Reply + use<>, Infallible> {
        let limit = self.config.amount_history_load;
        debug!("Loading history of {limit} elements (default)");

        match self.database.get_history(Some(limit)) {
            Ok(history) => Ok(warp::reply::html(self.render_history(&history))),
            Err(e) => {
                error!("Error getting history: {e:?}");
                Ok(warp::reply::html(format!("Error: {e:?}")))
            }
        }
    }


    async fn handle_count_request(
        &self,
        count: usize,
    ) -> Result<impl warp::Reply + use<>, Infallible> {
        info!("Loading history of {count} elements.");

        match self.database.get_history(Some(count)) {
            Ok(history) => Ok(warp::reply::html(self.render_history(&history))),
            Err(e) => {
                error!("Error getting history: {e:?}");
                Ok(warp::reply::html(format!("Error: {e:?}")))
            }
        }
    }


    fn render_history(&self, history: &[database::History]) -> String {
        let size = history.len();

        let items: Vec<String> = history
            .iter()
            .map(|entry| {
                let timestamp = DateTime::<Utc>::from_timestamp(entry.timestamp, 0)
                    .map(|dt| dt.format("%Y-%m-%d %H:%M:%S").to_string())
                    .unwrap_or_else(|| entry.timestamp.to_string());

                let links: Vec<&str> = entry.content.split(' ').collect();
                let links_html = self.extract_links(&timestamp, &links, &entry.file);

                format!(
                    "<article id=\"{}\" class=\"text-center\">{}</article>",
                    entry.uuid, links_html
                )
            })
            .collect();

        format!(
            r#"<html>
{}
<body>
<pre class="count"><span>small</span> history of: {}</pre>
<div>
{}
</div>
<footer>
<pre class="count">Sync eM ALL - version: {} - © 2015-2025 - Daniel (@dmilith) Dettlaff</pre>
</footer>
</body>
</html>"#,
            Self::head(),
            size,
            items.join(" "),
            env!("CARGO_PKG_VERSION")
        )
    }


    fn extract_links(&self, timestamp: &str, links: &[&str], file: &str) -> String {
        links
            .iter()
            .filter(|l| !l.is_empty())
            .map(|link| {
                if link.ends_with("png")
                    || link.ends_with("jpg")
                    || link.ends_with("jpeg")
                    || link.ends_with("gif")
                {
                    format!(
                        r#"<a href="{link}"><img src="{link}"></img><span class="caption">{timestamp} - {file}</span></a>"#
                    )
                } else {
                    format!(
                        r#"<a href="{link}"><img src="data:image/jpeg;base64,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"><span class="caption">{timestamp} - {file}</span></div></a>"#
                    )
                }
            })
            .collect::<Vec<_>>()
            .join(" ")
    }


    fn head() -> &'static str {
        r#"<head>
  <title>Small dashboard</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
  <style>
    article.item { vertical-align: top; display: block; text-align: center; }
    img { background-color: grey; padding: 0.5em; margin-top: 3em; margin-left: 2em; margin-right: 2em; }
    .caption { display: block; }
    .count { display: block; margin: 0.5em; font-weight: bold; text-align: center; }
    pre.count { margin: 2em; }
    pre.count span { font-size: 1.6em; }
    body { background-color: #e1e1e1; }
    footer { display: block; margin: 1.6em; margin-top: 3.2em; text-align: center; }
  </style>
</head>"#
    }
}
