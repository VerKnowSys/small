defmodule SyncEmAllApplication do
  use Application


  def main [] do
    {_ok, _any} = SyncSupervisor.start_link
    Timer.sleep :infinity
  end


  def start(_type, _args) do
    SyncSupervisor.start_link
  end
end
