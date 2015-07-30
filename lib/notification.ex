defmodule Notification do

  def send message do
    case System.cmd "/usr/local/bin/growlnotify", ["-n", "SyncEmAll", "-m", "\"#{message}\""] do
      {results, 0} ->
        {:ok, "Notification sent"}

      {_, res} ->
        {:error, "Can't send notification. Error: #{res}"}
    end
  end

end
