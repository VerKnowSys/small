defmodule SyncSupervisor do
  use Supervisor

  import Cfg
  require Logger


  def start :normal, [] do
    start_link
  end


  def get_initial_log_level do
    result = System.get_env "MIX_ENV"
    cond do
      result == "dev" ->
        :debug

      result == nil ->
        :debug

      result == "prod" ->
        :info

      result == "test" ->
        :debug
    end
  end


  def start_link do
    log_level get_initial_log_level
    config_check
    Supervisor.start_link __MODULE__, [], [name: __MODULE__]
  end


  # supervisor callback
  def init params do
    Logger.debug "Supervisor params: #{inspect params}"
    children = [
      worker(QueueAgent, [], [restart: :permanent]),
      worker(Sftp, [], [restart: :permanent]),
      worker(Small, [], [restart: :permanent]),
    ]
    supervise children, [strategy: :one_for_one, max_restarts: 1000, max_seconds: 5]
  end

end
