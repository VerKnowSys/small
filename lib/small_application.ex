defmodule SmallApplication do
  require Logger
  use Application
  import Notification
  alias :timer, as: Timer


  def main _ do
    notification "Launching SmallApplication", :start
    SyncSupervisor.start_link
    Timer.sleep :infinity
  end


end
