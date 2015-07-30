defmodule Notification do

  @doc """
  Sends notification using growlnotify utility

  ## Examples

      iex> Notification.send "abc"
      {:ok, "Notification sent"}

  """
  @spec send(message :: String.t) :: {:ok, String.t} | {:error, String.t}
  def send message do
    case System.cmd "/usr/local/bin/growlnotify", ["-n", "SyncEmAll", "-m", "\"#{message}\""] do
      {results, 0} ->
        {:ok, "Notification sent"}

      {_, res} ->
        {:error, "Can't send notification. Error: #{res}"}
    end
  end

end
