small - Sync 'eM ALL - [Syndir](https://github.com/VerKnowSys/Syndir) successor/ replacement.
=========

## REQUIREMENTS:

* OSX 10.x (not really required)
* Erlang OTP 18.x-19.x (required)
* Elixir 1.4.x (required)


## USED INTERNALY:

* https://github.com/VerKnowSys/fs


## FEATURES:

* Supervised "Let it crash" architecture with basic self healing.
* SSH Public Key authentication only (with encrypted keys support)
* Stream file of any size to remote through SFTP (SSH) channels
* Persistent Queue and History (mnesia disk only backend by default)
* Support for text database dumping (erl tuple format) with auto dump each 6 hours (by default)
* Basic Web History (localhost:8000) with ability to specify custom number of elements to show (localhost:8000/123)
* Asynchronous by design (whenever possible)
* Remote management through Elixir/ Erlang console. By default Small runs as "smallENV" - where ENV is one of modes: test, dev, prod (`epmd -names` to see available applications)


## CONFIGURATION:

By default Small keeps it's data under ~/Library/Small/ (or ~/.small/ under other POSIX systems)

Since version 0.12.1 Small uses external dynamic configuration under ~/Library/Small/config.ex (or ~/.small/config.ex respectively). File contains an Elixir [Keyword](https://hexdocs.pm/elixir/Keyword.html) very similar to JSON.

Below's an example of the configuration used by me:


```elixir
[
  username: "dmilith",
  hostname: "verknowsys.com",
  ssh_port: 60022,
  address: "http://s.verknowsys.com/",
  remote_path: "/home/dmilith/Web/Public/Sshots/",
  ssh_key_pass: "",
  notifications: [
    start: true,
    clipboard: true,
    upload: true,
    error: true
  ],
  sounds: [
    start: false,
    start_sound: "Glass",
    clipboard: false,
    clipboard_sound: "Tink",
    upload: true,
    upload_sound: "Hero",
    error: true,
    error_sound: "Sosumi"
  ],
  open_history_on_start: false
]
```


## USAGE:


```
# Build and install "Small":
bin/release
(sudo) bin/install
```

```
# Launch Small in console mode:
bin/console

# Start main supervisor:
> SyncSupervisor.start_link

```

## Autostart for user:

```
# there's /Projects/small directory hardcoded in this xml file.
cp $(pwd)/LaunchAgents/com.verknowsys.SyncEmAll.plist ~/Library/LaunchAgents/
`
