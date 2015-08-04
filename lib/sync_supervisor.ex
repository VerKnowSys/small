defmodule SyncSupervisor do
  use Supervisor

  import Cfg
  require Logger


  def start :normal, [] do
    start_link
  end


  def start_link do
    config_check
    Supervisor.start_link(__MODULE__, [], [{:name, __MODULE__}])
  end


  # supervisor callback
  def init([]) do
    children = [
      worker(QueueAgent, [], [restart: :permanent]),
      worker(Sftp, [], [restart: :permanent]),
      worker(SyncEmAll, [], [restart: :permanent])
    ]
    supervise children, [strategy: :one_for_one, max_restarts: 1000, max_seconds: 5]
  end

end
