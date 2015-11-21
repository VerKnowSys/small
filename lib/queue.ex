defmodule Queue do
  use GenServer
  require Lager
  import Lager

  @name __MODULE__


  ## Client API
  def start_link opts \\ [] do
    GenServer.start_link __MODULE__, :ok, [name: __MODULE__] ++ opts
  end


  def init :ok do
    notice "Launching Persistent Queue"
    {:ok, self}
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


  @doc """
  Gets state of all elements.
  """
  def get_all do
    DB.get_queue
  end


  @doc """
  Add a record to current state (only if record not already on list)
  """
  def put record do
    DB.add_to_queue record
  end


  @doc """
  Removes a record from current state.
  """
  def remove record do
    debug "Removing record from queue: #{inspect record}"
    DB.remove_from_queue record
  end
end
