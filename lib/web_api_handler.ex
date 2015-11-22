defmodule WebApi.Handler do
  require Lager
  import Lager

  @moduledoc """
  Provides handler for cowboy
  """


  def init {_any, :http}, req, [] do
    {:ok, req, :undefined}
  end


  @spec extract_links(timestamp :: String.t, links :: String.t, file :: String.t) :: String.t
  def extract_links timestamp, links, file do
    links |> (Enum.map fn link ->
      if String.ends_with? link, ["png", "jpg", "jpeg", "gif"] do
        "<a href=\"#{link}\"><img src=\"#{link}\"></img><span class=\"caption\">#{timestamp} - #{file}</span></a>"
      else
        "<a href=\"#{link}\"><img src=\"http://findicons.com/icon/download/203385/text_x_xslfo/128/png\"><span class=\"caption\">#{timestamp} - #{file}</span></div></a>"
      end
    end)
    |> Enum.join " "
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
    img { background-color: grey; padding: 0.5em; margin-top: 3em; margin-left: 2em; margin-right: 2em; }
    .caption { display: block; }
    body { background-color: #e1e1e1; }
  </style>
</head>
"""
  end


  def outer_route collection, req, state do
    {:ok, req} = :cowboy_req.reply 200, [],
      "<html>" <> head <> "<body><div>" <>
      (collection
        |> (Enum.map fn %Database.History{user_id: _, content: links, timestamp: ts, file: file, uuid: uuid} ->
          links_list = links |> String.split " "
          "<div id=\"#{uuid}\" class=\"text-center\">" <> extract_links(ts, links_list, file) <> "</div>"
        end)
        |> Enum.join " ") <> "</div></body></html>", req
    {:ok, req, state}
  end


  @spec history_amount(String.t | integer) :: integer
  defp history_amount(input) when is_binary(input), do: history_amount Integer.parse input
  defp history_amount(input) when is_number(input) and input > 10, do: input
  defp history_amount(_), do: 10


  def route path, args, req, state do
    history = DB.get_history
    debug "REQ: #{inspect req}"
    case path do
      "/" ->
        history |> (Enum.take history_amount args) |> outer_route req, state

      "/all" ->
        history |> outer_route req, state
    end
  end


  def handle req, state do
    case req do
      {:http_req, _, :ranch_tcp, :keepalive, pid, "GET", :"HTTP/1.1", {{_, _, _, _}, _}, _, _, _, path, _, args, _, [], _, [{"connection", ["keep-alive"]}], _, [], _, "", _, _, _, [], "", _} ->
        info "Pid #{inspect pid} is handling request for: #{path}"
        route path, args, req, state

      _a ->
        {:ok, req, state}
    end
  end


  def terminate _reason, _request, _state do
    :ok
  end
end
