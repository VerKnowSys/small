use crate::*;
use anyhow::{Context, Result};
use chrono::{Local, NaiveTime};
use serde::{Deserialize, Serialize};
use std::{fs, path::PathBuf};


/// Multiple configurations for sync
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Configs {
    pub configs: Vec<Config>,
    pub notifications: NotificationSettings,
    pub sounds: SoundSettings,
    pub open_history_on_start: bool,
}

/// A single configuration entry
#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq)]
pub struct Config {
    pub username: String,
    pub hostname: String,
    pub ssh_key: String,
    pub ssh_port: u16,
    pub address: String,
    pub remote_path: String,
    pub ssh_key_pass: String,
    pub watch_path: String,
    pub active_at: String, // hour range when to activate it: example: "9:01:00-15:55:00"
    pub default: bool,
}


#[derive(Debug, Copy, Clone, Serialize, Deserialize, Default)]
pub struct NotificationSettings {
    pub start: bool,
    pub clipboard: bool,
    pub upload: bool,
    pub error: bool,
}


#[derive(Debug, Clone, Serialize, Deserialize, Default)]
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


#[derive(Debug, Clone, Default)]
pub struct AppConfig {
    pub configs: Vec<Config>,
    pub notifications: NotificationSettings,
    pub sounds: SoundSettings,
    pub open_history_on_start: bool,
    pub env: String,
    pub fs_check_interval: u64,
    pub amount_history_load: usize,
    pub db_autodump_interval: u64,
    pub ssh_connection_timeout: u64,
    pub sftp_buffer_size: usize,
    pub webapi_port: u16,
}


impl AppConfig {
    pub fn new() -> Result<Self> {
        let env = std::env::var("ENV").unwrap_or_else(|_| "prod".to_string());
        let config_file = Self::default_config_file();

        if !config_file.exists() {
            anyhow::bail!("No configuration file: {:?}", config_file);
        }

        let config_content = fs::read_to_string(&config_file)
            .context(format!("Cannot open config file: {:?}", config_file))?;

        let config: Configs =
            toml::from_str(&config_content).context("Failed to parse config file")?;

        for config in &config.configs {
            Self::validate_config(config)?;
        }

        let webapi_port = match env.as_str() {
            "dev" => 8001,
            "test" => 8002,
            _ => 8000,
        };

        Ok(AppConfig {
            configs: config.configs.clone(),
            notifications: config.notifications,
            sounds: config.sounds,
            env,
            open_history_on_start: config.open_history_on_start,
            fs_check_interval: 1000, // ms
            amount_history_load: 50,
            db_autodump_interval: 21600000, // 6 hours in ms
            ssh_connection_timeout: 30000,
            sftp_buffer_size: 262144,
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


    // selects the current config based on the time
    pub fn select_config(&self) -> Result<Config> {
        let now = Local::now().time();

        let configs = &self.configs;
        let config = configs.iter().find(|cfg| {
            let range: Vec<&str> = cfg.active_at.split('-').collect();
            if range.len() > 2 {
                error!("Wrong format of the time range. Should be: HH:MM:SS-HH:MM:SS");
                return false;
            }
            let time_start = NaiveTime::parse_from_str(range[0], "%H:%M:%S")
                .expect("Valid time is expected");
            let time_end = NaiveTime::parse_from_str(range[1], "%H:%M:%S")
                .expect("Valid time is expected");

            now >= time_start && now <= time_end
        });

        let default_config = configs
            .iter()
            .find(|cfg| cfg.default)
            .expect("One of configs has to be the default!");

        if let Some(cfg) = config {
            debug!(
                "Selected config: {configuration:?}",
                configuration = Config {
                    ssh_key_pass: String::from("<redacted>"), /* don't print the ssh key in logs */
                    ..cfg.clone()
                }
            );
        }

        match config {
            Some(cfg) => Ok(cfg.clone()),
            None => {
                debug!(
                    "No config to select by the active_at range. Selecting the default one."
                );
                Ok(default_config.clone())
            }
        }
    }


    pub fn project_root_dir() -> PathBuf {
        let home = home::home_dir().expect("Could not determine home directory");
        home.join(Self::data_dir_base().trim_start_matches('/'))
    }


    pub fn project_dir(&self) -> PathBuf {
        Self::project_root_dir().join(&self.env)
    }


    pub fn db_dumps_dir(&self) -> PathBuf {
        Self::project_root_dir().join(format!(".sqlite-dumps-{}", self.env))
    }


    pub fn default_config_file() -> PathBuf {
        Self::project_root_dir().join("config.toml")
    }


    pub fn database_path(&self) -> PathBuf {
        self.project_dir().join("small.db")
    }
}
