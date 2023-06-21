defmodule SmallApplication do
  require Logger
  use Application
  import Notification
  import Cfg
  alias :timer, as: Timer


  def start _, _ do
    main []
  end


  def launch_periodic_dump do
    Logger.info "Initializing periodic dumper"
    Timer.apply_interval dump_interval(), DB, :dump_mnesia, []
  end


  def main param do
    Cfg.config_check()
    content = "Launching SmallApplication v#{version()}"
    Logger.info content
    notification content, :start
    case SyncSupervisor.start_link() do
      {:ok, pid} ->
        Logger.info "Initializing Mnesia backend and backing up current db state.."
        DB.init_and_start
        DB.dump_mnesia "current"

        if config()[:open_history_on_start] do
          Logger.debug "Open on start enabled"
          Logger.info "Automatically opening http dashboard: http://localhost:#{webapi_port()} in default browser."
          System.cmd "open", ["http://localhost:#{webapi_port()}"]
        end

        case launch_periodic_dump() do
          {:ok, pd_pid} ->
            Logger.debug "Periodic dump spawned in background (triggered each #{dump_interval()/360} hours)"
            Logger.info "SyncSupervisor started properly with pid: #{inspect pid}"

          {:error, error} ->
            Logger.error "Periodic dump spawn failed with error: #{inspect error}"
        end

      {:error, err} ->
        Logger.error "CRIT: SyncSupervisor error: #{inspect err}"
    end

    if param == "stay" do
      Logger.warn " Eternal watch skipped on demand."
    else
      Logger.info "Starting an eternal watch.."
      Timer.sleep :infinity
    end
    {:ok, self()}
  end


end
