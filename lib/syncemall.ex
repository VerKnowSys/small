defmodule SyncEmAll do
  use ExFSWatch, dirs: [System.get_env("HOME") <> "/Pictures/Screenshots"]

  def callback(:stop) do
    IO.puts "STOP"
  end

  def callback(file_path, events) do
    IO.inspect {file_path, events}
  end
end
