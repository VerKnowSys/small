use super::*;
use crate::{
    config::{AppConfig, Config},
    database::{Database, QueueItem},
    *,
};
use chrono::{Datelike, Local, NaiveTime, Weekday};


#[test]
fn test_file_extension() {
    assert_eq!(file_extension("/path/to/file.txt"), ".txt");
    assert_eq!(file_extension("/path/to/file.png"), ".png");
    assert_eq!(file_extension("/path/to/file"), "");
}


#[test]
fn test_size_kib() {
    assert_eq!(size_kib(1024), 1.0);
    assert_eq!(size_kib(2048), 2.0);
    assert_eq!(size_kib(512), 0.5);
}


#[test]
pub fn select_config_test_range() {
    let now = NaiveTime::parse_from_str("12:05:00", "%H:%M:%S").unwrap();

    let config1 = Config {
        active_at: String::from("12:01:00-15:15:00"),
        ..Config::default()
    };
    let config2 = Config {
        active_at: String::from("17:01:00-22:15:00"),
        ..Config::default()
    };
    let app_config = AppConfig {
        configs: vec![config1, config2],

        ..AppConfig::default()
    };

    let config = app_config.configs.iter().find(|cfg| {
        let range: Vec<&str> = cfg.active_at.split('-').collect();
        if range.len() > 2 || range.is_empty() {
            panic!("Length > 2 or == 0");
        }
        let time_start =
            NaiveTime::parse_from_str(range[0], "%H:%M:%S").expect("Valid time is expected");
        let time_end =
            NaiveTime::parse_from_str(range[1], "%H:%M:%S").expect("Valid time is expected");

        now >= time_start && now <= time_end
    });
    assert!(config.is_some());
}


#[test]
pub fn select_config_test_default() {
    let config1 = Config {
        active_at: String::from("12:01:00-15:15:00"),
        default: true,
        ..Config::default()
    };
    let config2 = Config {
        active_at: String::from("17:01:00-22:15:00"),
        ..Config::default()
    };
    let app_config = AppConfig {
        configs: vec![config1.clone(), config2],

        ..AppConfig::default()
    };

    let default_config = app_config.configs.iter().find(|cfg| cfg.default);
    assert!(default_config.is_some());
    assert_eq!(default_config.unwrap(), &config1);
}

#[test]
pub fn select_config_test_active_on() {
    let today = Local::now().weekday();
    let tomorrow = today.succ();

    let config1 = Config {
        active_at: String::from("00:00:00-23:59:59"),
        active_on: vec![today],
        ..Config::default()
    };
    let config2 = Config {
        active_at: String::from("00:00:00-23:59:59"),
        active_on: vec![tomorrow],
        ..Config::default()
    };
    let default_config = Config {
        active_at: String::from("00:00:00-00:00:01"), // not active now
        default: true,
        ..Config::default()
    };

    let app_config = AppConfig {
        configs: vec![config1.clone(), config2, default_config],
        ..AppConfig::default()
    };

    let selected_config = app_config.select_config().unwrap();
    assert_eq!(selected_config, config1);
}
