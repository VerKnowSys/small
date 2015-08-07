use Mix.Config

# project directory - used to help find out helper when running in escript mode:
config :fs, :project_dir, (to_char_list "/Projects/small/")

# path to be watched for file events:
config :fs, :path, System.get_env("HOME") <> "/Pictures/Screenshots"

config :small, :sftp_buffer_size, 131_072
config :small, :fs_check_interval, 30_000
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
      notifications: [start: true, clipboard: true, upload: true, error: true]
    ],
    "michal" => [
      username: "michal",
      hostname: "phoebe.tallica.pl",
      ssh_port: 60022,
      address: "http://s.tallica.pl/",
      remote_path: "/Users/michal/Screenshots/",
      ssh_key_pass: "",
      notifications: [start: true, clipboard: true, upload: true, error: true]
    ]
  }

config :logger, :console,
  format: "\n$time [$level] $metadata$message",
  metadata: [:user_id],
  level: :info
