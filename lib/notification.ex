defmodule Notification do

  @doc """
  Sends notification using growlnotify utility

  ## Examples

      iex> Notification.send "abc"
      :ok

  """
  @spec send(message :: String.t) :: :ok | :error
  def send message do
    case System.cmd "/usr/local/bin/growlnotify", ["-n", "SyncEmAll", "-m", "\"#{message}\""] do
      {_, 0} ->
        :ok

      {_, _} ->
        :error
    end
  end

end
