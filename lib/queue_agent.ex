defmodule QueueAgent do
  require Lager
  import Lager

  @name __MODULE__


  def start_link do
    notice "Launching QueueAgent"
    initial_state = []
    Agent.start_link(fn -> initial_state end, name: @name)
  end


  @doc """
  Gets first state element on list state.
  """
  def first do
    Agent.get @name, fn state ->
      if Enum.empty? state do
        :empty
      else
        [head | _tail] = state
        head
      end
    end
  end


  @doc """
  Gets state of all elements. Don't modify the state
  """
  def get_all do
    Agent.get @name, fn state ->
      state
    end
  end


  @doc """
  Add an element to current state only if element not already on list
  """
  def put element do
    Agent.update @name, fn state ->
      if Enum.member? state, element do
        state
      else
        [element | state]
      end
    end
  end


  @doc """
  Removes an element from current state.
  """
  def remove element do
    Agent.update @name, fn state ->
      Enum.reject state, fn el ->
        el == element
      end
    end
  end

end
