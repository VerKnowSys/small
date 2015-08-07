defmodule SmallApplication do
  require Logger
  use Application
  alias :timer, as: Timer


  def main _ do
    Notification.send "Launching SmallApplication"
    SyncSupervisor.start_link
    Timer.sleep :infinity
  end


end
