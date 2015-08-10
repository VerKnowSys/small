defmodule SmallApplication do
  require Lager
  use Application
  import Notification
  import Cfg
  alias :timer, as: Timer


  def start _, _ do
    main []
  end


  def main _ do
    content = "Launching SmallApplication v#{version}"
    Lager.notice content
    notification content, :start
    case SyncSupervisor.start_link do
      {:ok, pid} ->
        Lager.notice "SyncSupervisor started properly with pid: #{inspect pid}"

      {:error, err} ->
        Lager.error "SyncSupervisor error: #{inspect err}"
    end
    Timer.sleep :infinity
  end


end
