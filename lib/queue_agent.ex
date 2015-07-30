defmodule QueueAgent do
    require Logger

    @name __MODULE__


    def start_link do
        Logger.info "Launching QueueAgent"
        initial_state = []
        Agent.start_link(fn -> initial_state end, name: @name)
    end


    @doc """
    Pops first state element and remove popped element from current state.
    """
    def pop do
        Agent.get_and_update @name, fn state ->
            [head | tail] = state
            {head, tail}
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
    Add an element to current state
    """
    def put key do
        Agent.update @name, fn state -> [key | state] end
    end

end
