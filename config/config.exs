use Mix.Config


# path to be watched for file events:
config :fs, :path, System.get_env("HOME") <> "/Pictures/Screenshots"
# absolute path to events listener executable
config :fs, :events_helper, to_char_list "/Projects/small/deps/fs/priv/mac_listener"

config :small, :user_helper, "/Projects/small/bin/reattach-to-user-namespace"
config :small, :sftp_buffer_size, 131_072
config :small, :fs_check_interval, 60_000
config :small, :ssh_connection_timeout, 5_000
config :small, :config,
  %{
    "dmilith" => [
      username: "dmilith",
      hostname: "verknowsys.com",
      ssh_port: 60022,
      address: "http://s.verknowsys.com/",
      remote_path: "/home/dmilith/Web/Public/Sshots/",
      ssh_key_pass: "",
      notifications: [start: true, clipboard: true, upload: true, error: true, sound: true, sound_name: "Glass"]
    ],
    "michal" => [
      username: "michal",
      hostname: "phoebe.tallica.pl",
      ssh_port: 60022,
      address: "http://s.tallica.pl/",
      remote_path: "/Users/michal/Screenshots/",
      ssh_key_pass: "",
      notifications: [start: true, clipboard: true, upload: true, error: true, sound: true, sound_name: "Default"]
    ]
  }

config :logger, :console,
  format: "\n$time [$level] $metadata$message",
  metadata: [:user_id]
