defmodule SyncEmAll do
  require Logger

  @spec dirs :: String.t
  def dirs, do: System.get_env("HOME") <> "/Pictures/Screenshots"

  use ExFSWatch, dirs: [dirs]

  def callback(:stop) do
    Logger.info "STOP"
    {:ok, "Stopped"}
  end

  def match_events(events, match \\ [:created, :renamed]) do
    Enum.any? events, fn event ->
      Enum.member? match, event
    end
  end

  def match_exts(filename, pattern \\ ~r/\.[a-zA-Z0-9]{2,4}$/) do
    Regex.match? pattern, filename
  end

  def callback(file_path, events) do
    IO.inspect {file_path, events}

    if match_events(events) && match_exts(Path.basename(file_path)) do
      Logger.info "Matched file: " <> file_path
      username = System.get_env "USER"
      random_uuid = UUID.uuid4
      config = ConfigAgent.get username
      unless config do
        raise "Unknown user #{username} for ConfigAgent. Define your user and settings first!"
      end
      link = "#{config[:address]}#{random_uuid}.png"
      remote_dest_file = "#{config[:remote_path]}#{random_uuid}.png"

      QueueAgent.put {:add, file_path, remote_dest_file, random_uuid}
      Clipboard.put link
      Logger.info "Link copied to clipboard: #{link}"
      Logger.debug "Adding an element to queue (#{file_path} -> #{remote_dest_file})"
      Sftp.add
      Notification.send "Link synchronized: #{link}"
    end
  end

end
