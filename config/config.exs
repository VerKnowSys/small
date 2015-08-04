use Mix.Config


config :fs, :path, System.get_env("HOME") <> "/Pictures/Screenshots"
config :syncemall, :fs_check_interval, 30_000
config :syncemall, :config,
  %{
    "dmilith" => [
      username: "dmilith",
      hostname: "verknowsys.com",
      ssh_port: 60022,
      address: "http://s.verknowsys.com/",
      remote_path: "/home/dmilith/Web/Public/Sshots/",
      ssh_key_pass: "",
    ],
    "michal" => [
      username: "michal",
      hostname: "phoebe.tallica.pl",
      ssh_port: 60022,
      address: "http://s.tallica.pl/",
      remote_path: "/Users/michal/Screenshots/",
      ssh_key_pass: "",
    ]
  }
