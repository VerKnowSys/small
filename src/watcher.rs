use crate::{
    config::AppConfig,
    database::{Database, QueueItem},
    *,
};
use anyhow::Result;
use notify::{Config, Event, RecommendedWatcher, RecursiveMode, Watcher};
use std::{path::Path, sync::Arc};
use tokio::sync::mpsc;


#[derive(Debug)]
pub struct FileWatcher {
    config: Arc<AppConfig>,
    database: Arc<Database>,
}


impl FileWatcher {
    pub fn new(config: Arc<AppConfig>, database: Arc<Database>) -> Self {
        FileWatcher {
            config,
            database,
        }
    }


    pub async fn start(self: Arc<Self>) -> Result<()> {
        info!("Launching Small Filesystem Handler");
        let config = self
            .config
            .select_config()
            .expect("One of configs should always be selected!");
        info!("Watching path: {}", config.watch_path);

        let (tx, mut rx) = mpsc::unbounded_channel();
        let mut watcher = RecommendedWatcher::new(
            move |res: Result<Event, notify::Error>| {
                if let Ok(event) = res {
                    let _ = tx.send(event);
                }
            },
            Config::default(),
        )?;

        watcher.watch(Path::new(&config.watch_path), RecursiveMode::NonRecursive)?;
        info!("Filesystem non-recursive events watcher initialized");

        // Keep watcher alive and process events
        while let Some(event) = rx.recv().await {
            if let Err(e) = self.handle_event(event).await {
                error!("Error handling file event: {e:?}");
            }
        }

        Ok(())
    }


    async fn handle_event(&self, event: Event) -> Result<()> {
        let temp_pattern = regex::Regex::new(r".*-[a-zA-Z]{4,}$")?;
        for path in event.paths {
            let path_str = path.to_string_lossy().to_string();
            debug!("Handling event: {:?} for path {path_str}", event.kind);
            if !path.exists() {
                debug!(
                    "File doesn't exist: {path_str} after event {:?}. Skipped process_event",
                    event.kind
                );
                continue;
            }
            if temp_pattern.is_match(&path_str) {
                debug!("{path_str} matches temp file name! Skipping");
                continue;
            }
            self.process_event(&path_str)?;
        }

        Ok(())
    }


    fn process_event(&self, file_path: &str) -> Result<()> {
        debug!("Processing event for path: {file_path}");
        let config = self
            .config
            .select_config()
            .expect("One of configs should always be selected!");
        let uuid_from_file =
            uuid::Uuid::new_v3(&uuid::Uuid::NAMESPACE_OID, file_path.as_bytes()).to_string();
        let remote_dest_file = format!("{}/{uuid_from_file}", config.remote_path);

        // Add to queue
        let queue_item = QueueItem {
            local_file: file_path.to_string(),
            remote_file: remote_dest_file,
            uuid: uuid_from_file,
        };
        self.database.add_to_queue(&queue_item)?;
        debug!("Added file to queue: {file_path}");
        Ok(())
    }
}
