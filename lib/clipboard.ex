defmodule Clipboard do

  @doc """
  Puts text given as param to clipboard. Works on OSX only (for now)

  ## Examples

      iex> Clipboard.put "abc"
      {:ok, "Copied successfully"}

  """
  def put text do
    case System.cmd "sh", ["-c", "echo \"$0\" | pbcopy", "#{text}"] do
      {_result, 0} ->
        {:ok, "Copied successfully"}

      {_, res} ->
        {:error, "Can't copy to clipboard. Error: #{res}"}
    end
  end

end
