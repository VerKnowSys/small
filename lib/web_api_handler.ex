defmodule WebApi.Handler do
  require Lager
  import Lager

  @moduledoc """
  Provides handler for cowboy
  """


  def init {_any, :http}, req, [] do
    {:ok, req, :undefined}
  end


  defp extract_links input_string do
    [timestamp | link] = String.split input_string, " - "
    "<img src=\"#{List.first link}\"></img><span class=\"caption\">#{timestamp}</span>"
  end


  def head do """
<head>
  <title>Small dashboard</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
  <script src="//code.jquery.com/jquery-1.11.3.min.js"></script>
  <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>
  <style>
    div.item { vertical-align: top; display: inline-block; text-align: center; }
    img { background-color: grey; padding: 0.4em; margin-top: 1.5em; }
    .caption { display: block; }
  </style>
</head>
"""
  end


  def callback path, req, state do
    history = DB.get_history
    case path do
      "/" ->
        list = history
          |> (Stream.take 20)
          |> Enum.map fn hist -> "<div class=\"text-center\">" <> (extract_links hist) <> "</div>" end
        {:ok, req} = :cowboy_req.reply 200, [],
          "<html>" <> head <> "<body><div>" <> (Enum.join list, " ") <> "</div></body></html>", req
        {:ok, req, state}

      "/all" ->
        list = history
          |> Enum.map fn hist -> "<div class=\"text-center\">" <> (extract_links hist) <> "</div>" end
        {:ok, req} = :cowboy_req.reply 200, [],
          "<html>" <> head <> "<body><div>" <> (Enum.join list, " ") <> "</div></body></html>", req
        {:ok, req, state}
    end
  end


  def handle req, state do
    debug "Handling http request: #{inspect req}"
    case req do
      {:http_req, _, :ranch_tcp, :keepalive, pid, "GET", :"HTTP/1.1", {{_, _, _, _}, _}, _, _, _, path, _, _, _, [], _, [{"connection", ["keep-alive"]}], _, [], _, "", _, _, _, [], "", _} ->
        info "Pid #{inspect pid} is handling request for: #{path}"
        callback path, req, state

      _ ->
        callback "/", req, state
    end
  end


  def terminate _reason, _request, _state do
    :ok
  end
end
