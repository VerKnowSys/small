use Mix.Config

mix_env = System.get_env("MIX_ENV") || "dev"
mix_home = System.get_env("HOME") || "/tmp"

# Logger
config :logger, :console, format: "$time $message\n"

# path to be watched for file events:
config :fs, :path, mix_home <> "/Pictures/Screenshots"
# absolute path to events listener executable
helper_path = if File.exists?("/Users/Shared/Small/bin/mac_listener"), do: "/Users/Shared/Small/bin/mac_listener", else: pwd <> "/bin/mac_listener"
Config.config :fs, :events_helper, to_charlist helper_path
  case :os.type() do
    {:unix, :darwin} -> "/Library/Small/"
    {:unix, _}       -> "/.small/"
  end
) <> mix_env)

config :small, :amount_history_load, 16
config :small, :webapi_port, 8000
config :small, :webapi_dev_port, 8001
config :small, :webapi_test_port, 8002
config :small, :sftp_write_timeout, 15_000
config :small, :sftp_open_channel_timeout, 15_000
config :small, :sftp_start_channel_timeout, 15_000
config :small, :sftp_buffer_size, 131_072
config :small, :fs_check_interval, 2_000
config :small, :ssh_connection_timeout, 10_000
config :small, :mnesia_autodump_interval, 21_600_000 # 6h


# config :exlager, level: :debug
# config :lager,
#   [
#     colored: true,
#     colors: [
#       {:debug,     "\e[1;36m" },
#       {:info,      "\e[0;38m" },
#       {:notice,    "\e[1;37m" },
#       {:warning,   "\e[1;33m" },
#       {:error,     "\e[1;31m" },
#       {:critical,  "\e[1;35m" },
#       {:alert,     "\e[1;44m" },
#       {:emergency, "\e[1;41m" }
#     ],
#     # crash_log: "#{project_dir}/log/crash.log",
#     # error_logger_hwm: 30, # max 30 messages/s
#     # handlers: [
#     #   lager_console_backend: :notice,
#     #   lager_file_backend: [
#     #     file: "error.log",
#     #     level: :error,
#     #   ]
#     # ],
#   ]

