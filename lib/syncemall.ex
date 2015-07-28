defmodule SyncEmAll do
  use ExFSWatch, dirs: [System.get_env("HOME") <> "/Pictures/Screenshots"]

  def callback(:stop) do
    IO.puts "STOP"
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
      IO.puts "Matched file: " <> file_path
    end
  end
end
