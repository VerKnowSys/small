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


  def main _ do
    notice "Starting Mnesia Database Backend"
    DB.init_and_start

    content = "Launching SmallApplication v#{version}"
    notice content
    notification content, :start
    case SyncSupervisor.start_link do
      {:ok, pid} ->
        notice "SyncSupervisor started properly with pid: #{inspect pid}"

      {:error, err} ->
        critical "SyncSupervisor error: #{inspect err}"
    end

    Timer.sleep :infinity
  end


end
