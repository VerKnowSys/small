use anyhow::Result;
use std::process::Command;

pub fn send(message: &str, sound_name: Option<&str>) -> Result<()> {
    let sound_command = if let Some(sound) = sound_name {
        format!("sound name \"{}\"", sound)
    } else {
        String::new()
    };

    let script = format!(
        "display notification \"{}\" {} with title \"Small\"",
        message, sound_command
    );

    let output = Command::new("/usr/bin/osascript")
        .args(["-e", &script])
        .output()?;

    if output.status.success() {
        Ok(())
    } else {
        anyhow::bail!("Failed to send notification")
    }
}

pub fn notification(
    message: &str,
    notification_type: &str,
    config: &crate::config::Config,
) -> Result<()> {
    let should_notify = match notification_type {
        "start" => config.notifications.start,
        "clipboard" => config.notifications.clipboard,
        "upload" => config.notifications.upload,
        "error" => config.notifications.error,
        _ => false,
    };

    if !should_notify {
        return Ok(());
    }

    log::debug!(
        "Notification of type {} with result: {}",
        notification_type,
        should_notify
    );

    let sound_name = match notification_type {
        "start" if config.sounds.start => Some(config.sounds.start_sound.as_str()),
        "clipboard" if config.sounds.clipboard => Some(config.sounds.clipboard_sound.as_str()),
        "upload" if config.sounds.upload => Some(config.sounds.upload_sound.as_str()),
        "error" if config.sounds.error => Some(config.sounds.error_sound.as_str()),
        _ => None,
    };

    send(message, sound_name)?;

    if notification_type == "error" {
        anyhow::bail!("{}", message);
    }

    Ok(())
}

pub mod clipboard {
    use anyhow::Result;
    // use std::io::Write;
    use std::process::{Command, Stdio};

    pub fn put(text: &str) -> Result<()> {
        let mut child = Command::new("sh")
            .args(["-c", "echo \"$0\" | tr -d '\\n' | pbcopy"])
            .arg(text)
            .stdin(Stdio::piped())
            .spawn()?;

        child.wait()?;
        Ok(())
    }

    // pub fn get() -> Result<String> {
    //     let output = Command::new("pbpaste").output()?;

    //     if output.status.success() {
    //         Ok(String::from_utf8_lossy(&output.stdout).to_string())
    //     } else {
    //         anyhow::bail!("Clipboard error: {}", output.status)
    //     }
    // }
}
