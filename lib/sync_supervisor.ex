defmodule SyncSupervisor do
  use Supervisor

  import Cfg
  require Lager


  def start :normal, [] do
    start_link
  end


  def start_link do
    log_level get_initial_log_level
    config_check
    Supervisor.start_link __MODULE__, [], [name: __MODULE__]
  end


  # supervisor callback
  def init _params do
    Lager.debug "Supervisor params: #{inspect _params}"
    children = [
      worker(QueueAgent, [], [restart: :permanent]),
      worker(Sftp, [], [restart: :permanent]),
      worker(Small, [], [restart: :permanent]),
    ]
    supervise children, [strategy: :one_for_one, max_restarts: 1000, max_seconds: 5]
  end

end
