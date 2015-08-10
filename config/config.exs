use Mix.Config


# path to be watched for file events:
config :fs, :path, System.get_env("HOME") <> "/Pictures/Screenshots"
# absolute path to events listener executable
config :fs, :events_helper, to_char_list "/Projects/small/deps/fs/priv/mac_listener"

config :small, :user_helper, "/Projects/small/bin/reattach-to-user-namespace"
config :small, :sftp_buffer_size, 131_072
config :small, :fs_check_interval, (if Mix.env == :dev, do: 50_000, else: 5_000)
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
      ]
    ],
    "michal" => [
      username: "michal",
      hostname: "phoebe.tallica.pl",
      ssh_port: 60022,
      address: "http://s.tallica.pl/",
      remote_path: "/Users/michal/Screenshots/",
      ssh_key_pass: "",
      notifications: [start: true, clipboard: true, upload: true, error: true],
      sounds: [
        start: false,
        start_sound: "Glass",
        clipboard: false,
        clipboard_sound: "Tink",
        upload: true,
        upload_sound: "Hero",
        error: true,
        error_sound: "Sosumi",
      ]
    ]
  }


config :exlager, level: :debug
config :lager,
  [
    colored: true,
    colors: [
      {:debug,     "\e[1;36m" },
      {:info,      "\e[0;38m" },
      {:notice,    "\e[1;37m" },
      {:warning,   "\e[1;33m" },
      {:error,     "\e[1;31m" },
      {:critical,  "\e[1;35m" },
      {:alert,     "\e[1;44m" },
      {:emergency, "\e[1;41m" }
    ],
    crash_log: "log/crash.log",
    error_logger_hwm: 10, # max 10 messages/s
    handlers: [
      lager_console_backend: :notice,
      lager_file_backend: [
        file: "error.log",
        level: :error,
      ]
    ],
  ]
