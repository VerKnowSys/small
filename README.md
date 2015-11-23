small - Sync 'eM ALL - [Syndir](https://github.com/VerKnowSys/Syndir) successor.
=========

## REQUIREMENTS:

* OSX 10.x (required)
* Erlang OTP 18.x (required)
* Elixir 1.0.x (required)
* Sofin 0.84.x (optional)
* Zsh 5.x (optional)
* Tmux 1.x (optional)

## USED INTERNALY:

* https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard
* https://github.com/VerKnowSys/fs


## FEATURES:

* Supervised "Let it crash" architecture
* SSH Public Key authentication only (with encrypted keys support)
* Stream file of any size to remote through SFTP (SSH)
* Persistent Queue and History (mnesia disk only backend by default)
* Basic Web History (localhost:8000)
* Asynchronous (when possible)
* Automatically merge multiple results in clipboard
* Remote management through Elixir/ Erlang console. By default Small runs as "smallENV" - where ENV is one of modes: test, dev, prod (`epmd -names` to see available applications)


## WARNING:

You'll need to put bin/reattach-to-user-namespace binary to /usr/local/bin for OSX Notifications to work properly in tmux session (used in bin/launcher).


## USAGE:

# bin/script_name schema:

```
# script_name => launch app in default mode (dev)
# script_name prod => launch app in production mode
bin/$scriptname [prod|dev|...]
```

# Examples:

```
# Build and Launch "Small" in background (or attach to already running) tmux session.
bin/launcher
```

```
# Build and Launch "Small" in foreground in default dev mode:
bin/build
bin/run
```

```
# Build and Launch "Small" in foreground in default dev mode:
bin/build
bin/run
```

```
# Build and Launch "Small" in foreground in REPL in production mode:
bin/console prod
```

```
# Launch Small in console mode:
bin/console

> SyncSupervisor.start_link
> ...
```

## Autostart for user

`cp $(pwd)/LaunchAgents/com.verknowsys.SyncEmAll.plist ~/Library/LaunchAgents/`
