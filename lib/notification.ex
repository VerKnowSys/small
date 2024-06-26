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
  @spec send(String.t) :: :ok | :error
  @spec send(String.t, sound_name :: Atom.t()) :: :ok | :error
  def send(message, sound_name \\ :no_sound) do
    sound_command = if sound_name == :no_sound, do: "", else: "sound name \"#{sound_name}\""

    case System.cmd("/usr/bin/osascript", [
           "-e",
           "display notification \"#{message}\" #{sound_command} with title \"Small\""
         ]) do
      {_, 0} ->
        :ok

      {_, _} ->
        :error
    end
  end

  @doc """
  Send notifications based on user settings.
  Notify with error level will automatically raise an exception.
  Types: [:start, :clipboard, :upload, :error]
  """
  @spec notification(String.t, Term.t()) :: nil
  def notification(message, type) do
    config = config()

    if config[:notifications][type] do
      Logger.debug(
        "Notification of type #{inspect(type)} with result: #{inspect(config[:notifications][type])}"
      )

      if config[:sounds][type] do
        Notification.send(
          message,
          config[:sounds][String.to_atom(Atom.to_string(type) <> "_sound")]
        )
      else
        Notification.send(message)
      end

      if type == :error do
        raise message
      end
    end
  end
end
