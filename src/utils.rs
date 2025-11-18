use crate::*;
use anyhow::Result;
use std::{
    fs,
    io::{self, Read, Write},
    path::Path,
};
use tracing_subscriber::{EnvFilter, fmt};


/// Initialize the instruments-subscriber
pub fn initialize() {
    let env_log = match EnvFilter::try_from_env("LOG") {
        Ok(env_value_from_env) => env_value_from_env,
        Err(_) => EnvFilter::from("info"),
    };
    fmt()
        .compact()
        .with_thread_names(false)
        .with_thread_ids(false)
        .with_ansi(true)
        .with_env_filter(env_log)
        .with_filter_reloading()
        .init();
}


pub fn put_to_clipboard(text: &str) -> Result<()> {
    let mut clipboard = clippers::Clipboard::get();
    clipboard.write_text(text)?;
    Ok(())
}


pub fn local_file_size<P: AsRef<Path>>(file_path: P) -> Result<u64> {
    let metadata = fs::metadata(file_path)?;
    Ok(metadata.len())
}


pub fn size_kib(size_in_bytes: u64) -> f64 {
    (size_in_bytes as f64) / 1024.0
}


pub fn file_extension<P: AsRef<Path>>(path: P) -> String {
    path.as_ref()
        .extension()
        .and_then(|e| e.to_str())
        .map(|e| format!(".{e}"))
        .unwrap_or_default()
}


pub fn stream_file_to_remote<R, W>(
    reader: &mut R,
    writer: &mut W,
    buffer_size: usize,
    total_size: u64,
) -> Result<()>
where
    R: Read,
    W: Write,
{
    let mut buffer = vec![0u8; buffer_size];
    // let mut bytes_written = 0u64;
    let chunks = if total_size > 0 {
        (total_size / buffer_size as u64) + 1
    } else {
        1
    };

    info!(
        "Streaming file of size: {:.2}KiB to remote server..",
        size_kib(total_size)
    );

    let mut chunk_index = 0u64;
    loop {
        let bytes_read = reader.read(&mut buffer)?;
        if bytes_read == 0 {
            break;
        }

        writer.write_all(&buffer[..bytes_read])?;
        chunk_index += 1;

        let percent = if chunks > 0 {
            (chunk_index as f64 * 100.0) / chunks as f64
        } else {
            100.0
        };

        eprint!("\rProgress: {percent:.2}% ");
        io::stderr().flush()?;
    }

    eprintln!(); // New line after progress
    info!("Upload complete!");
    Ok(())
}
