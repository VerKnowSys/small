# Small - Sync'eM ALL (Rust Implementation)

**NOTE**: This is a Rust port of the original Elixir application.


## Overview

Small is a file synchronization application that watches for file changes and automatically uploads them via SFTP to a remote server. It features:

- Supervised architecture with automatic recovery
- SSH Public Key authentication (with encrypted keys support)
- Stream files of any size to remote through SFTP channels
- Persistent Queue and History (SQLite backend)
- Web-based history viewer (http://localhost:8000)
- Asynchronous by design using Tokio
- macOS notifications

## Requirements

- Rust 1.90+ (required)
- macOS 10.10+ (only because it supports macOS Notification Center via osascript)
- SSH2 key (`.ssh/id_ed25519` by default, optionally with password, but held in the config.toml plaintext)

## Configuration

Small requires a SSH accessible backend where files will be stored and hosted from. For this I use Nginx configuration like this:

```nginx
server {
        listen 80;
        server_name s.verknowsys.com;
        location / {
           return 302 https://s.verknowsys.com/$request_uri;
        }
        autoindex off;
        index index.html;
}

server {
        listen 443 ssl;
        http2 on;

        ssl_certificate_key /Services/Certsd/certs/wild_verknowsys.com/domain.key;
        ssl_certificate /Services/Certsd/certs/wild_verknowsys.com/chained.pem;

        server_name s.verknowsys.com;
        root /Web/Sshots/;

        ssl_protocols TLSv1.3 TLSv1.2;
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:10m;
        ssl_session_tickets off;

        # enable HSTS for A+ grade:
        add_header Strict-Transport-Security "max-age=63072000" always;
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";

        autoindex off;
}
```

Small uses a TOML configuration file located at:
- macOS: `~/Library/Small/config.toml`
- Unix: `~/.small/config.toml`

Example configuration:

```toml
# Small Configuration
open_history_on_start = false

[[configs]]
default = false
active_at = "00:00:00-8:59:59"
username = "otheruser"
hostname = "my.ssh.host.com"
ssh_port = 50022
ssh_key = ".ssh/id_ed25519"
ssh_key_pass = ""
address = "https://your.site.com/"
remote_path = "/Web/Sshots"
watch_path = "/Users/your-user/Desktop"

[[configs]]
default = true
active_at = "9:00:00-17:00:00"
username = "anuser"
hostname = "some.web.address.com"
ssh_port = 22
ssh_key = ".ssh/id_ed25519"
ssh_key_pass = ""
address = "https://some.web.endpoint.com/"
remote_path = "/Destination/Web/Dir"
watch_path = "/Users/your-user/Pictures/Screenshots"

[[configs]]
default = false
active_at = "17:00:01-23:59:59"
username = "otheruser"
hostname = "my.ssh.host.com"
ssh_port = 50022
ssh_key = ".ssh/id_ed25519"
ssh_key_pass = ""
address = "https://your.site.com/"
remote_path = "/Web/Sshots"
watch_path = "/Users/your-user/Desktop"

# Notification settings
[notifications]
start = true
clipboard = true
upload = true
error = true

# Sound settings
[sounds]
start = false
start_sound = "Glass"
clipboard = false
clipboard_sound = "Tink"
upload = true
upload_sound = "Hero"
error = true
error_sound = "Sosumi"
```

NOTE: The time ranges are compared naively, so for example "17:00:01-8:59:59" will not work as expected. Additional config part with the time range since "0:00:00" is required as in the example above.

## Building

```bash
# Build release version
cargo build --release

# The binary will be at: target/release/small
```

## Installation

```bash
bin/install
```

Create your `config.toml` file as shown above.

## Run it

```bash
cargo run --release
```

The application will:
1. Start watching the parent directory of your project directory for file changes
2. Upload any new or modified files via SFTP
3. Copy the upload URL to your clipboard
4. Maintain a history viewable at http://localhost:8000

## Development

```bash
# Run in development mode
ENV=dev LOG=debug cargo run

# Run tests
cargo test
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
├── lib.rs            # Common library module
├── notification.rs   # macOS notifications and clipboard
├── sftp.rs           # SFTP upload manager
├── utils.rs          # Utility functions
├── tests.rs          # Test functions
├── watcher.rs        # File system watching
└── webapi.rs         # Web history server
```

## Autostart (macOS)

To run Small automatically on login, you can create a LaunchAgent plist file or use any service manager.

Example using a simple shell script in your shell profile:

```bash
bin/install
```

## License

MIT

## Author

Daniel (@dmilith) Dettlaff
