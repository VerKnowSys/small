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
    time = Timer.tc fn ->
      SyncSupervisor.start_link
    end
    case time do
      {elapsed, _} ->
        Logger.info "SmallApplication started in: #{elapsed/1000}ms"
        :ok
    end
    Timer.sleep :infinity
  end


end
