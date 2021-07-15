defmodule Clipboard do
  import Notification

  @doc """
  Puts text given as param to clipboard. Works on OSX only (for now)

  ## Examples

      iex> Clipboard.put "abc"
      :ok

  """
  @spec put(text :: String.t) :: :ok | :error
  def put text do
    case System.cmd "sh", ["-c", "echo \"$0\" | tr -d '\n' | pbcopy", "#{text}"] do
      {_result, 0} ->
        notification "Link copied to clipboard", :clipboard
        :ok

      {_, _} ->
        :error
    end
  end


  @doc """
  Returns current clipboard contents
  """
  def get do
    case System.cmd "pbpaste", [] do
      {result, 0} ->
        IO.iodata_to_binary result

      {_, reason} ->
        {:error, "Clipboard error: #{inspect reason}"}
    end
  end


end
