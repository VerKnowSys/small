defmodule Notification do
  require Logger


  @doc """
  Sends notification using native OSX Notification Center

  ## Examples

      iex> Notification.send "abc"
      :ok

  """
  @spec send(message :: String.t) :: :ok | :error
  def send message do
    # NOTE: Using - https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard
    reattach_helper = File.exists? "/usr/local/bin/reattach-to-user-namespace"
    case reattach_helper do
      true ->
        case System.cmd "/usr/local/bin/reattach-to-user-namespace", ["/usr/bin/osascript", "-e", "display notification \"#{message}\" sound name \"Default\" with title \"SyncEmAll\""] do
          {_, 0} ->
            :ok

          {_, _} ->
            :error
        end

      false ->
        case System.cmd "/usr/bin/osascript", ["-e", "display notification \"#{message}\" sound name \"Default\" with title \"SyncEmAll\""] do
          {_, 0} ->
            :ok

          {_, _} ->
            :error
        end
    end
  end

end
