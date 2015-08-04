defmodule Notification do

  @doc """
  Sends notification using native OSX Notification Center

  ## Examples

      iex> Notification.send "abc"
      :ok

  """
  @spec send(message :: String.t) :: :ok | :error
  def send message do
    case System.cmd "osascript", ["-e", "display notification \"#{message}\" sound name \"Default\" with title \"SyncEmAll\""] do
      {_, 0} ->
        :ok

      {_, _} ->
        :error
    end
  end

end
