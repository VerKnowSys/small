defmodule Notification do
  require Logger
  import Cfg


  @doc """
  Sends notification using native OSX Notification Center.
  For Tmux sessions, Small includes helper application to fix issues with Notification Center not working under Tmux. More: https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard.

  ## Examples

      iex> Notification.send "abc"
      :ok

  """
  @spec send(message :: String.t) :: :ok | :error
  def send message, sound_name \\ :no_sound do
    sound_command = if (sound_name == :no_sound), do: "", else: sound_command = "sound name \"#{sound_name}\""

    case File.exists? user_helper do
      true ->
        case System.cmd user_helper, ["/usr/bin/osascript", "-e", "display notification \"#{message}\" #{sound_command} with title \"Small\""] do
          {_, 0} ->
            :ok

          {_, _} ->
            :error
        end

      false ->
        case System.cmd "/usr/bin/osascript", ["-e", "display notification \"#{message}\" #{sound_command} with title \"Small\""] do
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
  Types: [:start, :clipboard, :upload, :error]
  """
  def notification message, type do
    if config[:notifications][type] do
      Logger.debug "Notification of type #{inspect type} with result: #{inspect config[:notifications][type]}"
      if config[:notifications][:sound] do
        Notification.send message, config[:notifications][:sound_name]
      else
        Notification.send message
      end
      if type == :error do
        raise message
      end
    end
  end


end
