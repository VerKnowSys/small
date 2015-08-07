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
    SyncSupervisor.start_link
    Timer.sleep :infinity
  end


end
