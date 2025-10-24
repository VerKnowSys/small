//! Small

#![forbid(unsafe_code)]

//! Crate docs
#![deny(
    // missing_docs,
    unstable_features,
    missing_debug_implementations,
    missing_copy_implementations,
    trivial_casts,
    trivial_numeric_casts,
    unused_import_braces,
    unused_qualifications
)]
#![allow(unused_imports, dead_code)]


//
// Public modules:
//

/// Configuration part of the app
pub mod config;

/// Sqlite db API
pub mod database;
/// MacOS Notifications
pub mod notification;
/// SFTP sync operations
pub mod sftp;
/// Utilities
pub mod utils;
/// Screenshot file watcher
pub mod watcher;
/// The local Web API
pub mod webapi;

/// Make the TEMP_PATTERN a lazy static
use lazy_static::lazy_static;
use regex::Regex;
lazy_static! {
    static ref TEMP_PATTERN: Regex = Regex::new(r".*-[a-zA-Z0-9]{4,}$").unwrap();
}

pub use tracing::{debug, error, info, instrument, trace, warn};
pub use utils::*;

//
// Private modules:
//

#[cfg(test)]
mod tests;
