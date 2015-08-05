SyncEmAll
=========

WARNING:
You'll need to put bin/reattach-to-user-namespace binary to /usr/local/bin for OSX Notifications to work properly in tmux session (used in bin/launcher).


USAGE:

To run normally:

```
mix do deps.get, deps.compile, compile
iex -S mix
```

or to run in production environment (if you have tmux and prebuilt reattach-to-user-namespace installed):

```
bin/launcher
```
