# Small - Sync 'eM ALL (Rust Version)

**NOTE**: This is a Rust port of the original Elixir application. See [README.md](README.md) for the original documentation.

## Overview

Small is a file synchronization application that watches for file changes and automatically uploads them via SFTP to a remote server. It features:

- Supervised architecture with automatic recovery
- SSH Public Key authentication (with encrypted keys support)
- Stream files of any size to remote through SFTP channels
- Persistent Queue and History (SQLite backend)
- Web-based history viewer (http://localhost:8000)
- Asynchronous by design using Tokio
- macOS notifications and clipboard integration

## Requirements

- Rust 1.70+ (required)
- macOS 10.10+ (for notifications and clipboard features)
- SSH key pair configured in `~/.ssh/`

## Configuration

Small uses a TOML configuration file located at:
- macOS: `~/Library/Small/config.toml`
- Linux/Unix: `~/.small/config.toml`

Example configuration:

```toml
username = "dmilith"
hostname = "verknowsys.com"
ssh_port = 60022
address = "http://s.verknowsys.com/"
remote_path = "/home/dmilith/Web/Public/Sshots/"
ssh_key_pass = ""

[notifications]
start = true
clipboard = true
upload = true
error = true

[sounds]
start = false
start_sound = "Glass"
clipboard = false
clipboard_sound = "Tink"
upload = true
upload_sound = "Hero"
error = true
error_sound = "Sosumi"

open_history_on_start = false
```

## Building

```bash
# Build release version
cargo build --release

# The binary will be at: target/release/small
```

## Installation

```bash
# Build and copy to /usr/local/bin
cargo build --release
sudo cp target/release/small /usr/local/bin/

# Create configuration directory
mkdir -p ~/Library/Small  # or ~/.small on Linux
```

Create your `config.toml` file as shown above.

## Usage

```bash
# Run directly
./target/release/small

# Or if installed
small
```

The application will:
1. Start watching the parent directory of your project directory for file changes
2. Upload any new or modified files via SFTP
3. Copy the upload URL to your clipboard
4. Maintain a history viewable at http://localhost:8000

## Development

```bash
# Run in development mode
MIX_ENV=dev cargo run

# Run tests
cargo test

# Enable debug logging
RUST_LOG=debug cargo run
```

## Differences from Elixir Version

- **Database**: Uses SQLite instead of Mnesia for persistence
- **Runtime**: Uses Tokio async runtime instead of Erlang OTP
- **File Watching**: Uses `notify` crate instead of `fs` Erlang library
- **Web Server**: Uses `warp` instead of Cowboy
- **Configuration**: Uses TOML format instead of Elixir syntax
- **Performance**: Generally faster startup and lower memory footprint

## Project Structure

```
src/
├── config.rs         # Configuration management
├── database.rs       # SQLite database operations
├── main.rs           # Application entry point
├── notification.rs   # macOS notifications and clipboard
├── sftp.rs           # SFTP upload manager
├── utils.rs          # Utility functions
├── watcher.rs        # File system watching
└── webapi.rs         # Web history server
```

## Autostart (macOS)

To run Small automatically on login, you can create a LaunchAgent plist file or use any service manager.

Example using a simple shell script in your shell profile:

```bash
# Add to ~/.zshrc or ~/.bash_profile
/usr/local/bin/small &
```

## License

Same license as the original Elixir version.

## Author

Original Elixir version: Daniel (@dmilith) Dettlaff  
Rust port: Converted from Elixir to Rust
