use anyhow::Result;
use notify::{Config, Event, RecommendedWatcher, RecursiveMode, Watcher};
use std::path::Path;
use std::sync::Arc;
use tokio::sync::mpsc;

use crate::config::AppConfig;
use crate::database::{Database, QueueItem};

pub struct FileWatcher {
    config: Arc<AppConfig>,
    database: Arc<Database>,
}

impl FileWatcher {
    pub fn new(config: Arc<AppConfig>, database: Arc<Database>) -> Self {
        FileWatcher { config, database }
    }

    pub async fn start(self: Arc<Self>) -> Result<()> {
        log::info!("Launching Small Filesystem Handler");
        log::info!("Watching path: {}", self.config.config.watch_path);

        let (tx, mut rx) = mpsc::unbounded_channel();

        let mut watcher = RecommendedWatcher::new(
            move |res: Result<Event, notify::Error>| {
                if let Ok(event) = res {
                    let _ = tx.send(event);
                }
            },
            Config::default(),
        )?;

        watcher.watch(
            Path::new(&self.config.config.watch_path),
            RecursiveMode::Recursive,
        )?;
        log::info!("Filesystem events watcher initialized");

        // Keep watcher alive and process events
        while let Some(event) = rx.recv().await {
            if let Err(e) = self.handle_event(event).await {
                log::error!("Error handling file event: {:?}", e);
            }
        }

        Ok(())
    }

    async fn handle_event(&self, event: Event) -> Result<()> {
        let temp_pattern = regex::Regex::new(r".*-[a-zA-Z]{4,}$")?;
        for path in event.paths {
            let path_str = path.to_string_lossy().to_string();

            log::debug!("Handling event: {:?} for path {}", event.kind, path_str);

            // Check if file exists
            if !path.exists() {
                log::debug!(
                    "File doesn't exist: {} after event {:?}. Skipped process_event",
                    path_str,
                    event.kind
                );
                continue;
            }

            // Handle temporary/unwanted files

            if temp_pattern.is_match(&path_str) {
                log::debug!("{} matches temp file name! Skipping", path_str);
                continue;
            }

            // Process the file event
            self.process_event(&path_str)?;
        }

        Ok(())
    }

    fn process_event(&self, file_path: &str) -> Result<()> {
        log::debug!("Processing event for path: {}", file_path);

        // Generate UUID for the file
        let uuid_from_file =
            uuid::Uuid::new_v3(&uuid::Uuid::NAMESPACE_OID, file_path.as_bytes()).to_string();

        let remote_dest_file = format!("{}{}", self.config.config.remote_path, uuid_from_file);

        // Add to queue
        let queue_item = QueueItem {
            local_file: file_path.to_string(),
            remote_file: remote_dest_file,
            uuid: uuid_from_file,
        };

        self.database.add_to_queue(&queue_item)?;
        log::debug!("Added file to queue: {}", file_path);

        Ok(())
    }
}
