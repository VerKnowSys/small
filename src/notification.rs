use crate::{
    config::{NotificationSettings, SoundSettings},
    *,
};
use anyhow::Result;
use std::process::Command;


pub fn send(message: &str, sound_name: Option<&str>) -> Result<()> {
    let sound_command = if let Some(sound) = sound_name {
        format!("sound name \"{sound}\"")
    } else {
        String::new()
    };

    let script =
        format!("display notification \"{message}\" {sound_command} with title \"Small\"");
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
    notifications: &NotificationSettings,
    sounds: &SoundSettings,
) -> Result<()> {
    let should_notify = match notification_type {
        "start" => notifications.start,
        "clipboard" => notifications.clipboard,
        "upload" => notifications.upload,
        "error" => notifications.error,
        _ => false,
    };

    if !should_notify {
        return Ok(());
    }

    debug!("Notification of type {notification_type} with result: {should_notify}");
    let sound_name = match notification_type {
        "start" if sounds.start => Some(sounds.start_sound.as_str()),
        "clipboard" if sounds.clipboard => Some(sounds.clipboard_sound.as_str()),
        "upload" if sounds.upload => Some(sounds.upload_sound.as_str()),
        "error" if sounds.error => Some(sounds.error_sound.as_str()),
        _ => None,
    };

    send(message, sound_name)?;
    if notification_type == "error" {
        anyhow::bail!("{message}");
    }

    Ok(())
}
