defmodule Queue do
  use GenServer
  require Logger

  @name __MODULE__


  ## Client API
  def start_link opts \\ [] do
    GenServer.start_link @name, :ok, [name: @name] ++ opts
  end


  def init :ok do
    Logger.info "Launching Persistent Queue"
    {:ok, self()}
  end


  @doc """
  Gets first state element on list state.
  """
  def first do
    queue = List.first DB.get_queue
    case queue do
      nil ->
        :empty
      _any ->
        queue
    end
  end

end
