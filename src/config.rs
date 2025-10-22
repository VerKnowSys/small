use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub username: String,
    pub hostname: String,
    pub ssh_port: u16,
    pub address: String,
    pub remote_path: String,
    pub ssh_key_pass: String,
    pub notifications: NotificationSettings,
    pub sounds: SoundSettings,
    pub open_history_on_start: bool,
    pub watch_path: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NotificationSettings {
    pub start: bool,
    pub clipboard: bool,
    pub upload: bool,
    pub error: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SoundSettings {
    pub start: bool,
    pub start_sound: String,
    pub clipboard: bool,
    pub clipboard_sound: String,
    pub upload: bool,
    pub upload_sound: String,
    pub error: bool,
    pub error_sound: String,
}

pub struct AppConfig {
    pub config: Config,
    pub env: String,
    pub fs_check_interval: u64,
    pub amount_history_load: usize,
    pub mnesia_autodump_interval: u64,
    pub ssh_connection_timeout: u64,
    pub sftp_buffer_size: usize,
    pub webapi_port: u16,
}

impl AppConfig {
    pub fn new() -> Result<Self> {
        let env = std::env::var("RUST_ENV").unwrap_or_else(|_| "prod".to_string());
        let config_file = Self::default_config_file();

        if !config_file.exists() {
            anyhow::bail!("No configuration file: {:?}", config_file);
        }

        let config_content = fs::read_to_string(&config_file)
            .context(format!("Cannot open config file: {:?}", config_file))?;

        let config: Config =
            toml::from_str(&config_content).context("Failed to parse config file")?;

        Self::validate_config(&config)?;

        let webapi_port = match env.as_str() {
            "dev" => 8001,
            "test" => 8002,
            _ => 8000,
        };

        Ok(AppConfig {
            config,
            env,
            fs_check_interval: 1000, // ms
            amount_history_load: 50,
            mnesia_autodump_interval: 21600000, // 6 hours in ms
            ssh_connection_timeout: 30000,
            sftp_buffer_size: 65536,
            webapi_port,
        })
    }

    fn validate_config(config: &Config) -> Result<()> {
        if config.username.is_empty() {
            anyhow::bail!("Required configuration value: username is empty!");
        }
        if config.hostname.is_empty() {
            anyhow::bail!("Required configuration value: hostname is empty!");
        }
        if config.ssh_port == 0 {
            anyhow::bail!("Required configuration value: ssh_port is zero!");
        }
        if config.address.is_empty() {
            anyhow::bail!("Required configuration value: address is empty!");
        }
        if config.remote_path.is_empty() {
            anyhow::bail!("Required configuration value: remote_path is empty!");
        }
        Ok(())
    }

    pub fn data_dir_base() -> &'static str {
        if cfg!(target_os = "macos") {
            "/Library/Small/"
        } else {
            "/.small/"
        }
    }

    pub fn project_root_dir() -> PathBuf {
        let home = home::home_dir().expect("Could not determine home directory");
        home.join(Self::data_dir_base().trim_start_matches('/'))
    }

    pub fn project_dir(&self) -> PathBuf {
        Self::project_root_dir().join(&self.env)
    }

    pub fn mnesia_dumps_dir(&self) -> PathBuf {
        Self::project_root_dir().join(format!(".sqlite-dumps-{}", self.env))
    }

    pub fn default_config_file() -> PathBuf {
        Self::project_root_dir().join("config.toml")
    }

    pub fn database_path(&self) -> PathBuf {
        self.project_dir().join("small.db")
    }
}
