use small_bin::*;

use anyhow::Result;
use config::AppConfig;
use database::Database;
use std::{env, fs, sync::Arc, time::Duration};
use tokio::time;


#[tokio::main]
async fn main() -> Result<()> {
    // Initialize the logger
    initialize();

    // Load configuration
    let config = Arc::new(AppConfig::new()?);
    let version = env!("CARGO_PKG_VERSION");

    info!("Launching Small v{}", version);

    // Send startup notification
    if let Err(e) = notification::notification(
        &format!("Launching SmallApplication v{version}"),
        "start",
        &config.notifications,
        &config.sounds,
    ) {
        warn!("Failed to send startup notification: {e:?}");
    }

    // Initialize database
    let db_path = config.database_path();
    let database = Arc::new(Database::new(&db_path)?);
    info!("Initializing database backend: {db_path:?}");

    // Start SFTP manager
    let (sftp_manager, _rx) = sftp::SftpManager::new(config.clone(), database.clone());
    let sftp_manager = Arc::new(sftp_manager);
    let sftp_handle = {
        tokio::spawn(async move {
            sftp_manager.start().await;
        })
    };

    // Start web API
    let web_api = Arc::new(webapi::WebApi::new(config.clone(), database.clone()));
    let web_handle = {
        tokio::spawn(async move {
            if let Err(e) = web_api.start().await {
                error!("Web API error: {e:?}");
            }
        })
    };

    // Open browser if configured
    if config.open_history_on_start {
        info!(
            "Automatically opening http dashboard: http://localhost:{} in default browser.",
            config.webapi_port
        );
        if let Err(e) = std::process::Command::new("open")
            .arg(format!("http://localhost:{}", config.webapi_port))
            .spawn()
        {
            warn!("Failed to open browser: {e:?}");
        }
    }

    // Start file watcher
    let file_watcher = Arc::new(watcher::FileWatcher::new(config.clone(), database.clone()));
    let watcher_handle = {
        tokio::spawn(async move {
            if let Err(e) = file_watcher.start().await {
                error!("File watcher error: {e:?}");
            }
        })
    };

    // Start periodic database dumper
    let dump_interval = config.db_autodump_interval;
    let periodic_dump_handle = {
        let dumps_dir = config.db_dumps_dir();
        fs::create_dir_all(&dumps_dir).ok();
        tokio::spawn(async move {
            info!(
                "Initializing periodic dumper (triggered every {} hours)",
                dump_interval / 3600000
            );
            let mut interval = time::interval(Duration::from_millis(dump_interval));
            loop {
                interval.tick().await; // the first tick is immediate
                interval.tick().await;
                let timestamp = chrono::Utc::now().format("%Y-%m-%d-%H-%M-%S").to_string();
                let dump_path = dumps_dir.join(format!("database.{timestamp}.db"));
                if let Err(e) = database.dump_to_file(&dump_path) {
                    error!("Failed to dump database: {e:?}");
                }
            }
        })
    };

    info!("Starting an eternal watch…");

    // Wait for all tasks
    tokio::select! {
        _ = sftp_handle => error!("SFTP manager stopped"),
        _ = web_handle => error!("Web API stopped"),
        _ = watcher_handle => error!("File watcher stopped"),
        _ = periodic_dump_handle => error!("Periodic dump stopped"),
    }

    Ok(())
}
