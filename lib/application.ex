defmodule SyncEmAllApplication do
  require Logger
  use Application


  def start _type, _args do
    SyncSupervisor.start_link
  end


end
