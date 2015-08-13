defmodule WebApi.Handler do
  require Lager
  import Lager

  @moduledoc """
  Provides handler for cowboy
  """
  @ets_table :webapi_handler
  @ets_key   :response
  @default_response "Sync eM ALL"

  def define_response response, timeout do
    response  = response || @default_response
    timeout = timeout || 0

    # if (:ets.info @ets_table) == :undefined do
    #   :ets.new @ets_table, [:set, :public, :named_table]
    # end
    # :ets.insert @ets_table, {@ets_key, {response, timeout}}
  end

  def init {_any, :http}, req, [] do
    {:ok, req, :undefined}
  end


  defp extract_links input_string do
    [timestamp | link] = String.split input_string, " - "
    "<img src=\"#{List.first link}\"></img><span class=\"caption\">#{timestamp}</span>"
  end


  def handle req, state do
    head = """
<head>
  <title>Small dashboard</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
  <script src="//code.jquery.com/jquery-1.11.3.min.js"></script>
  <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>
  <style>
    div.item { vertical-align: top; display: inline-block; text-align: center; }
    img { background-color: grey; padding: 0.4em; margin-top: 1em; }
    .caption { display: block; }
  </style>
</head>
"""
    list = DB.get_history |> Enum.map fn hist -> "<div class=\"text-center\">" <> (extract_links hist) <> "</div>" end
    debug "WebApi list: #{inspect list}"
    {:ok, req} = :cowboy_req.reply 200, [],
      "<html>" <> head <> "<body><div>" <> (Enum.join list, "<br/>") <> "</div></body></html>", req
    {:ok, req, state}
  end


  defp wait_for duration do
    if duration > 0 do
      current_pid = self
      spawn fn ->
        :timer.sleep duration
        send current_pid, :completed
      end

      receive do
        :completed -> nil  # do nothing
      end
    end
  end


  def terminate _reason, _request, _state do
    :ok
  end
end
