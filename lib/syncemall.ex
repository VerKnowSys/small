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
      dest_name = UUID.uuid4
      case username do
        "dmilith" ->
          link = "http://s.verknowsys.com/#{dest_name}.png"
          Clipboard.put link
          Logger.info "Link copied to clipboard: #{link}"
          Sftp.add file_path, "/home/#{username}/Web/Public/Sshots/#{dest_name}.png"
          Notification.send "Link synchronized: #{link}"
        _ ->
          Logger.error "You should define destination for your user ;P"
      end
    end
  end

end
