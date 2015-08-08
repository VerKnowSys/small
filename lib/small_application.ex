defmodule SmallApplication do
  require Logger
  use Application
  import Notification
  import Cfg
  alias :timer, as: Timer


  def start _, _ do
    main []
  end


  def main _ do
    content = "Launching SmallApplication v#{version}"
    Logger.info content
    notification content, :start
    case SyncSupervisor.start_link do
      {:ok, pid} ->
        Logger.info "SyncSupervisor started properly with pid: #{inspect pid}"

      {:error, err} ->
        Logger.error "SyncSupervisor error: #{inspect err}"
    end
    Timer.sleep :infinity
  end


end
