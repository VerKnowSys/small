mod config;
mod database;
mod notification;
mod sftp;
mod utils;
mod watcher;
mod webapi;

use anyhow::Result;
use std::sync::Arc;
use std::time::Duration;
use tokio::time;

use config::AppConfig;
use database::Database;

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize logger
    env_logger::Builder::from_default_env()
        .filter_level(log::LevelFilter::Info)
        .init();

    // Load configuration
    let config = Arc::new(AppConfig::new()?);
    let version = env!("CARGO_PKG_VERSION");

    log::info!("Launching SmallApplication v{}", version);

    // Send startup notification
    if let Err(e) = notification::notification(
        &format!("Launching SmallApplication v{}", version),
        "start",
        &config.config,
    ) {
        log::warn!("Failed to send startup notification: {:?}", e);
    }

    // Initialize database
    let db_path = config.database_path();
    let database = Arc::new(Database::new(&db_path)?);
    log::info!("Initializing database backend: {:?}", db_path);

    // Dump database on startup
    let dump_path = config.mnesia_dumps_dir().join("current.db");
    std::fs::create_dir_all(config.mnesia_dumps_dir())?;
    database.dump_to_file(&dump_path)?;

    // Start SFTP manager
    let (sftp_manager, _rx) = sftp::SftpManager::new(config.clone(), database.clone());
    let sftp_manager = Arc::new(sftp_manager);
    let sftp_handle = {
        let manager = sftp_manager.clone();
        tokio::spawn(async move {
            manager.start().await;
        })
    };

    // Start web API
    let web_api = Arc::new(webapi::WebApi::new(config.clone(), database.clone()));
    let web_handle = {
        let api = web_api.clone();
        tokio::spawn(async move {
            if let Err(e) = api.start().await {
                log::error!("Web API error: {:?}", e);
            }
        })
    };

    // Open browser if configured
    if config.config.open_history_on_start {
        log::info!(
            "Automatically opening http dashboard: http://localhost:{} in default browser.",
            config.webapi_port
        );
        if let Err(e) = std::process::Command::new("open")
            .arg(format!("http://localhost:{}", config.webapi_port))
            .spawn()
        {
            log::warn!("Failed to open browser: {:?}", e);
        }
    }

    // Start file watcher
    let file_watcher = Arc::new(watcher::FileWatcher::new(config.clone(), database.clone()));
    let watcher_handle = {
        let watcher = file_watcher.clone();
        tokio::spawn(async move {
            if let Err(e) = watcher.start().await {
                log::error!("File watcher error: {:?}", e);
            }
        })
    };

    // Start periodic database dumper
    let dump_interval = config.mnesia_autodump_interval;
    let periodic_dump_handle = {
        let db = database.clone();
        let dumps_dir = config.mnesia_dumps_dir();
        tokio::spawn(async move {
            log::info!(
                "Initializing periodic dumper (triggered each {} hours)",
                dump_interval / 3600000
            );
            let mut interval = time::interval(Duration::from_millis(dump_interval));
            loop {
                interval.tick().await;
                let timestamp = chrono::Utc::now().format("%Y-%m-%d-%H-%M-%S").to_string();
                let dump_path = dumps_dir.join(format!("database.{}.db", timestamp));
                if let Err(e) = db.dump_to_file(&dump_path) {
                    log::error!("Failed to dump database: {:?}", e);
                }
            }
        })
    };

    log::info!("SyncSupervisor started properly");
    log::info!("Starting an eternal watch..");

    // Wait for all tasks
    tokio::select! {
        _ = sftp_handle => log::error!("SFTP manager stopped"),
        _ = web_handle => log::error!("Web API stopped"),
        _ = watcher_handle => log::error!("File watcher stopped"),
        _ = periodic_dump_handle => log::error!("Periodic dump stopped"),
    }

    Ok(())
}
