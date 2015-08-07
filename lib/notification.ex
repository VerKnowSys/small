defmodule Notification do
  require Logger
  import Cfg


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
        case System.cmd "/usr/local/bin/reattach-to-user-namespace", ["/usr/bin/osascript", "-e", "display notification \"#{message}\" sound name \"Default\" with title \"Small\""] do
          {_, 0} ->
            :ok

          {_, _} ->
            :error
        end

      false ->
        case System.cmd "/usr/bin/osascript", ["-e", "display notification \"#{message}\" sound name \"Default\" with title \"Small\""] do
          {_, 0} ->
            :ok

          {_, _} ->
            :error
        end
    end
  end


  @doc """
  Send notifications based on user settings.
  Notify with error level will automatically raise an exception.
  """
  def notify message, type do
    if config[:notifications][type] do
      send "#{inspect message}"
      if type == :notify_error do
        raise message
      end
    end
  end


end
