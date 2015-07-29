defmodule SyncSupervisor do
  use Supervisor

  require Logger
  Logger.info "Loading supervisor"


  def main [] do
    start :normal, []
  end


  def start :normal, [] do
    start_link
  end


  def start_link do
    Supervisor.start_link(__MODULE__, [], [{:name, __MODULE__}])
  end

  # supervisor callback
  def init([]) do
    children = [
      worker(Sftp, [], []),
    ]
    supervise children, [strategy: :one_for_one, max_restarts: 1, max_seconds: 5]
  end

end
