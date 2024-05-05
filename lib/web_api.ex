defmodule WebApi do
  require Logger
  import Cfg
  use GenServer

  @node_name __MODULE__

  ## Client API
  def start_link(opts \\ []) do
    Logger.info("Launching Small WebApi")
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__] ++ opts)
  end

  defp routes do
    [
      {:_,
       [
         {:_, WebApi.Handler, []}
       ]}
    ]
  end

  def init(:ok) do
    # Application.ensure_started :crypto
    case Application.ensure_started(:cowboy) do
      {:error, cause} ->
        Logger.error(
          "An error occured when ensuring started Cowboy app. Cause: #{inspect(cause)}"
        )

      :ok ->
        Logger.debug("Ensuring Cowboy started")
    end

    dispatch = :cowboy_router.compile(routes())

    "#{@node_name}_#{webapi_port()}"
    |> :cowboy.start_http(10, [ip: {127, 0, 0, 1}, port: webapi_port()], [
      {:env, [{:dispatch, dispatch}]}
    ])

    {:ok, self()}
  end

  def start(:normal, []) do
    start_link()
  end
end
