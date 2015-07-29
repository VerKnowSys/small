defmodule SyncEmAll do

  def dirs, do: System.get_env("HOME") <> "/Pictures/Screenshots"
  use ExFSWatch, dirs: [dirs]
  require Logger


  def callback(:stop) do
    Logger.info "STOP"
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
      Sftp.add file_path, "/home/dmilith/Web/tmp1" # TODO
    end
  end

end
