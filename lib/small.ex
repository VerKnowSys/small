defmodule Small do
  require Logger
  use GenServer
  import Cfg

  alias :fs, as: FS


  ## Client API
  def start_link opts \\ [] do
    Logger.info "Launching Small Filesystem Handler"
    GenServer.start_link __MODULE__, :ok, [name: __MODULE__] ++ opts
  end


  def init :ok do
    Logger.debug "Subscribing filesystem events"
    FS.subscribe
    {:ok, self}
  end


  def start :normal, [] do
    start_link
  end


  def process_event event, file_path do
    if (File.exists? file_path) do
      Logger.debug "Handling event: #{inspect event} for path #{file_path}"
      random_uuid = UUID.uuid3 nil, file_path, :hex
      remote_dest_file = "#{config[:remote_path]}#{random_uuid}"
      record = {:add, file_path, remote_dest_file, random_uuid}
      Logger.debug "#{inspect record}"
      QueueAgent.put record
      Sftp.add
    else
      Logger.debug "File doesn't exists: #{file_path} after event #{inspect event}. Skipped process_event"
    end
  end


  def handle_info {pid, {:fs, :file_event}, {path, event}}, state do
    path = path |> List.to_string
    process_event event, path
    {:noreply, state}
  end


end
