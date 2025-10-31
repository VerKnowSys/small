use crate::*;
use anyhow::Result;
use chrono::{DateTime, Local, Utc};
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
        let count = history.len();
        let items: Vec<String> = history
            .iter()
            .map(|entry| {
                let timestamp = DateTime::<Utc>::from_timestamp(entry.timestamp, 0)
                    .map(|dt_utc| {
                        // convert Utc to Local, Utc isn't a standard time in Poland
                        DateTime::<Local>::from(dt_utc)
                    })
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
<pre class="count"><span>small</span> history of: {count}</pre>
<div>
{}
</div>
<footer>
<pre class="count">Sync eM ALL - version: {} - © 2015-2025 - Daniel (<a href="https://x.com/dmilith/" target="_blank">@dmilith</a>) Dettlaff</pre>
</footer>
</body>
</html>"#,
            Self::head(),
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
                        r#"<a href="{link}"><img src="{IMG_NO_MEDIA}"><span class="caption">{timestamp} - {file}</span></div></a>"#
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
    .count { display: block; margin: 0.5em; font-weight: bold; text-align: center; background: #CFCFCF }
    pre.count { margin: 2em; }
    pre.count span { font-size: 1.6em; }
    body { background-color: #e1e1e1; }
    footer { display: block; margin: 1.6em; margin-top: 3.2em; text-align: center; }
  </style>
</head>"#
    }
}
