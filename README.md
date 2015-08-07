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


## WARNING:

You'll need to put bin/reattach-to-user-namespace binary to /usr/local/bin for OSX Notifications to work properly in tmux session (used in bin/launcher).


## USAGE:

To run normally:

```
mix do deps.get, deps.compile, compile
iex -S mix
```

or to run in production environment (if you have tmux and prebuilt reattach-to-user-namespace installed):

```
bin/launcher
```

## Autostart for user

`cp $(pwd)/LaunchAgents/com.verknowsys.SyncEmAll.plist ~/Library/LaunchAgents/`
