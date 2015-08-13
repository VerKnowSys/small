defmodule WebApi do
  require Lager
  import Lager
  use GenServer

  @listener_name node
  @default_port 8000


  ## Client API
  def start_link opts \\ [] do
    notice "Launching Small WebApi"
    GenServer.start_link __MODULE__, :ok, [name: __MODULE__] ++ opts
  end


  def init :ok do
    Application.ensure_started :crypto
    Application.ensure_started :cowboy

    path = "/"
    # path = args[:path] || "/"
    port = @default_port
    WebApi.Handler.define_response "/", 1000

    dispatch = :cowboy_router.compile([
      {:_,
        [{path, WebApi.Handler, []}]
      }
    ])
    :cowboy.start_http "#{@listener_name}_#{port}", 10,
        [{:port, port}], [{:env, [{:dispatch, dispatch}]}]

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
