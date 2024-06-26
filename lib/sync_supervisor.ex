defmodule SyncSupervisor do
  use Supervisor

  import Cfg
  require Logger

  @spec start(:normal, []) :: :ignore | {:error, any()} | {:ok, pid()}
  def start(:normal, []) do
    start_link()
  end

  @spec start_link() :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link do
    Logger.info("Setting initial log level")
    log_level(get_initial_log_level())
    Logger.info("Performing configuration check")
    config_check()
    File.mkdir_p(Cfg.project_dir())
    File.mkdir_p(Cfg.mnesia_dumps_dir())
    Logger.info("Setting default Mnesia directory to #{Cfg.project_dir()}")
    Cfg.set_default_mnesia_dir(Cfg.project_dir())
    Logger.info("Setting default project directory to #{Cfg.project_dir() <> "/.."}")
    File.cd(Cfg.project_dir() <> "/..")

    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  # supervisor callback
  @spec init(any()) :: any()
  def init(params) do
    Logger.debug("Supervisor params: #{inspect(params)}")

    children = [
      {Queue, []},
      {WebApi, []},
      {Small, []},
      {Sftp, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
