defmodule WebApi do
  require Lager
  import Lager
  import Cfg
  use GenServer

  @listener_name node


  ## Client API
  def start_link opts \\ [] do
    notice "Launching Small WebApi"
    GenServer.start_link __MODULE__, :ok, [name: __MODULE__] ++ opts
  end


  def init :ok do
    Application.ensure_started :crypto
    Application.ensure_started :cowboy

    dispatch = :cowboy_router.compile([
      {:_,
        [
          {"/", WebApi.Handler, []},
          {"/all", WebApi.Handler, []}
        ]
      }
    ])
    :cowboy.start_http "#{@listener_name}_#{webapi_port}", 10,
        [ip: {127,0,0,1}, port: webapi_port], [{:env, [{:dispatch, dispatch}]}]

    {:ok, self}
  end


  def start :normal, [] do
    start_link
  end


  # def handle_info {_pid, {:webapi}, {config_key, config_value}}, state do
  #   {:noreply, state}
  # end

  # def stop, do: stop(@default_port)
  # def stop(port) do
  #   :cowboy.stop_listener("#{@listener_name}_#{port}")
  # end
end
