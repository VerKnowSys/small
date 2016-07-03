defmodule SmallApplication do
  require Lager
  import Lager
  use Application
  import Notification
  import Cfg
  alias :timer, as: Timer


  def start _, _ do
    main []
  end


  def launch_periodic_dump do
    info "Calling for aMnesia database dump!"
    Timer.apply_interval dump_interval, DB, :dump_mnesia, []
  end


  def main _ do
    content = "Launching SmallApplication v#{version}"
    notice content
    notification content, :start
    case SyncSupervisor.start_link do
      {:ok, pid} ->
        notice "Initializing Mnesia backend"
        DB.init_and_start

        notice "Invoking periodic dumper.."
        case launch_periodic_dump do
          {:ok, pid} ->
            debug "Periodic dump spawned: #{inspect pid}"

          {:error, error} ->
            error "Periodic dump spawn failed with error: #{inspect error}"
        end

        notice "SyncSupervisor started properly with pid: #{inspect pid}"
        if config[:open_history_on_start] do
          debug "Open on start enabled"
          notice "Automatically opening http dashboard: http://localhost:#{webapi_port} in default browser."
          System.cmd "open", ["http://localhost:#{webapi_port}"]
        end

      {:error, err} ->
        critical "SyncSupervisor error: #{inspect err}"
    end

    Timer.sleep :infinity
    {:ok, self}
  end


end
