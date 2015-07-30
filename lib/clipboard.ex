defmodule Clipboard do

  @doc """
  Puts text given as param to clipboard. Works on OSX only (for now)

  ## Examples

      iex> Clipboard.put "abc"
      :ok

  """
  @spec put(text :: String.t) :: :ok | :error
  def put text do
    case System.cmd "sh", ["-c", "echo \"$0\" | pbcopy", "#{text}"] do
      {_result, 0} ->
        :ok

      {_, _} ->
        :error
    end
  end

end
