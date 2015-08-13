defmodule SshSupervisor do
  use Supervisor

  import Cfg
  require Lager
  import Lager


  def start :normal, [] do
    start_link
  end


  def start_link do
    Supervisor.start_link __MODULE__, [], [name: __MODULE__]
  end


  # supervisor callback
  def init _params do
    notice "Starting SSH Supervisor"
    children = [
      worker(Sftp, [], [restart: :transient])
    ]
    supervise children, [strategy: :one_for_one, max_restarts: 1_000_000, max_seconds: 5]
  end

end
