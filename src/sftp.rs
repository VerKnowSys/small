use anyhow::{Context, Result};
use ssh2::Session;
use std::fs::File;
use std::io::BufReader;
use std::net::TcpStream;
use std::path::Path;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::mpsc;
use tokio::time;

use crate::config::AppConfig;
use crate::database::{Database, History, QueueItem};
use crate::notification::{clipboard, notification};
use crate::utils;

pub struct SftpManager {
    config: Arc<AppConfig>,
    database: Arc<Database>,
    // tx: mpsc::UnboundedSender<()>,
}

impl SftpManager {
    pub fn new(
        config: Arc<AppConfig>,
        database: Arc<Database>,
    ) -> (Self, mpsc::UnboundedReceiver<()>) {
        let (_tx, rx) = mpsc::unbounded_channel();
        (
            SftpManager {
                config,
                database,
                // tx,
            },
            rx,
        )
    }

    pub async fn start(self: Arc<Self>) {
        let mut interval = time::interval(Duration::from_millis(self.config.fs_check_interval));

        log::info!(
            "Starting SFTP queue processor with check interval: {}ms",
            self.config.fs_check_interval
        );

        loop {
            interval.tick().await;
            if let Err(e) = self.process_queue().await {
                log::error!("Error processing queue: {:?}", e);
            }
        }
    }

    async fn process_queue(&self) -> Result<()> {
        let queue = self.database.get_queue()?;

        if queue.is_empty() {
            return Ok(());
        }

        // Build clipboard content
        self.build_clipboard(&queue)?;

        // Process each queue item
        for item in queue {
            if let Err(e) = self.process_element(&item).await {
                log::error!("Error processing queue element: {:?}", e);
            }
        }

        Ok(())
    }

    fn build_clipboard(&self, queue: &[QueueItem]) -> Result<()> {
        let links: Vec<String> = queue
            .iter()
            .map(|item| {
                format!(
                    "{}{}{}",
                    self.config.config.address,
                    item.uuid,
                    utils::file_extension(&item.local_file)
                )
            })
            .collect();

        let content = links.join("\n");
        clipboard::put(&content)?;

        if self.config.config.notifications.clipboard {
            let _ = notification("Link copied to clipboard", "clipboard", &self.config.config);
        }

        Ok(())
    }

    async fn process_element(&self, item: &QueueItem) -> Result<()> {
        let path = Path::new(&item.local_file);

        // Check if file exists and is regular
        if !path.exists() || !path.is_file() {
            log::debug!(
                "Local file not found or not a regular file: {}. Skipping.",
                item.local_file
            );
            self.database.remove_from_queue(&item.uuid)?;
            return Ok(());
        }

        // Check for temp file pattern
        let temp_pattern = regex::Regex::new(r".*-[a-zA-Z]{4,}$")?;
        if temp_pattern.is_match(&item.local_file) {
            log::debug!("File matches temp pattern, skipping: {}", item.local_file);
            self.database.remove_from_queue(&item.uuid)?;
            return Ok(());
        }

        // Upload file
        let remote_file = format!(
            "{}{}",
            item.remote_file,
            utils::file_extension(&item.local_file)
        );
        self.send_file(&item.local_file, &remote_file).await?;

        // Add to history
        self.add_to_history(item)?;

        // Remove from queue
        self.database.remove_from_queue(&item.uuid)?;

        Ok(())
    }

    async fn send_file(&self, local_file: &str, remote_file: &str) -> Result<()> {
        let config = &self.config.config;

        // Connect via SSH
        let tcp = TcpStream::connect(format!("{}:{}", config.hostname, config.ssh_port))
            .context("Failed to connect to SSH server")?;
        tcp.set_read_timeout(Some(Duration::from_millis(
            self.config.ssh_connection_timeout,
        )))?;
        tcp.set_write_timeout(Some(Duration::from_millis(
            self.config.ssh_connection_timeout,
        )))?;

        let mut sess = Session::new()?;
        sess.set_tcp_stream(tcp);
        sess.handshake()?;

        // Authenticate
        sess.userauth_pubkey_file(
            &config.username,
            None,
            Path::new(&home::home_dir().unwrap())
                .join(".ssh/id_ed25519")
                .as_path(),
            if config.ssh_key_pass.is_empty() {
                None
            } else {
                Some(&config.ssh_key_pass)
            },
        )?;

        if !sess.authenticated() {
            anyhow::bail!("SSH authentication failed");
        }

        log::debug!("SSH connection established");

        // Start SFTP session
        let sftp = sess.sftp()?;
        log::debug!("SFTP session started");

        // Check remote file
        let local_size = utils::local_file_size(local_file)?;
        let remote_size = sftp
            .stat(Path::new(remote_file))
            .map(|stat| stat.size.unwrap_or(0))
            .unwrap_or(0);

        log::debug!(
            "Local file: {} ({}); Remote file: {} ({})",
            local_file,
            local_size,
            remote_file,
            remote_size
        );

        if remote_size > 0 && remote_size == local_size {
            log::info!("Found file of same size already uploaded. Skipping");
            return Ok(());
        }

        // Upload file
        log::info!("Uploading file to remote");
        let mut local = BufReader::new(File::open(local_file)?);
        let mut remote = sftp.create(Path::new(remote_file))?;

        utils::stream_file_to_remote(
            &mut local,
            &mut remote,
            self.config.sftp_buffer_size,
            local_size,
        )?;

        if self.config.config.notifications.upload {
            let _ = notification("Uploaded successfully.", "upload", &self.config.config);
        }

        Ok(())
    }

    fn add_to_history(&self, queue_item: &QueueItem) -> Result<()> {
        let content = format!(
            "{}{}{}",
            self.config.config.address,
            queue_item.uuid,
            utils::file_extension(&queue_item.local_file)
        );

        // Check if already in history
        let history = self.database.get_history(None)?;
        let exists = history.iter().any(|h| h.content.contains(&content));

        if !exists {
            let history_item = History {
                content,
                timestamp: crate::database::now_unix(),
                file: queue_item.local_file.clone(),
                uuid: uuid::Uuid::new_v4().to_string(),
            };
            self.database.add_history(&history_item)?;
        }

        Ok(())
    }

    // pub fn trigger(&self) {
    //     let _ = self.tx.send(());
    // }
}
