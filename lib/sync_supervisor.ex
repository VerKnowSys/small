defmodule SyncSupervisor do
  use Supervisor

  alias :timer, as: Timer

  require Logger
  Logger.info "Loading supervisor"


  def main [] do
    {_ok, _any} = start_link
    Timer.sleep :infinity
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
      worker(ConfigAgent, [], [restart: :permanent]),
      worker(QueueAgent, [], [restart: :permanent]),
      worker(Sftp, [], [restart: :permanent]),
      worker(SyncEmAll, [], [restart: :permanent])
    ]
    supervise children, [strategy: :one_for_one, max_restarts: 1000, max_seconds: 5]
  end

end
