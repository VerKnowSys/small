small - Sync 'eM ALL!
=========

## REQUIREMENTS:

* OSX 10.x (required)
* Erlang OTP 18.x (required)
* Elixir 1.0.x (required)
* Sofin 0.80.x (optional)
* Zsh 5.x (optional)
* Tmux 1.x (optional)

## USED INTERNALY:

* https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard
* https://github.com/VerKnowSys/fs


## FEATURES:

* Supervised "Let it crash" architecture
* Stream file of any size to remote through SFTP (ssh)
* Persistent Queue and History (mnesia disk only backend by default)
* Basic Web History (localhost:8000)
* Asynchronous (when possible)
* Automatically merge multiple results in clipboard
* Remote management through Elixir/ Erlang console. By default Small runs as "smallENV" - where ENV is one of modes: test, dev, prod (`epmd -names` to see available applications)


## WEAK SIDES:

* Still poorly handles TCP timeouts after longer machine sleep.
* Currently works only under Mac OSX 10.9.x or higher


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


## Autostart for user

`cp $(pwd)/LaunchAgents/com.verknowsys.SyncEmAll.plist ~/Library/LaunchAgents/`
