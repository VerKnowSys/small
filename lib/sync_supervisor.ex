defmodule SyncSupervisor do
  use Supervisor

  import Cfg
  require Lager
  import Lager


  def start :normal, [] do
    start_link
  end


  def start_link do
    notice "Setting initial log level"
    log_level get_initial_log_level
    info "Performing configuration check"
    config_check
    Supervisor.start_link __MODULE__, [], [name: __MODULE__]
  end


  # supervisor callback
  def init _params do
    debug "Supervisor params: #{inspect _params}"
    children = [
      (worker Queue, [], [restart: :permanent]),
      (worker Small, [], [restart: :permanent]),
      (worker WebApi, [], [restart: :permanent]),
      (worker Sftp, [], [restart: :permanent]),
    ]
    supervise children, [strategy: :one_for_one, max_restarts: 1_000_000, max_seconds: 5]
  end

end
