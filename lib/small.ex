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
    FS.subscribe()
    Logger.info "Filesystem events watcher initialized"
    {:ok, self()}
  end


  def start :normal, [] do
    start_link()
  end


  def process_event event, file_path do
    if File.exists? file_path do
      Logger.debug "Handling event: #{inspect event} for path #{file_path}"
      random_uuid = UUID.uuid3 nil, file_path, :hex
      remote_dest_file = "#{config()[:remote_path]}#{random_uuid}"
      DB.add_to_queue %Database.Queue{local_file: file_path, remote_file: remote_dest_file, uuid: random_uuid}
      Sftp.add
    else
      Logger.debug "File doesn't exists: #{file_path} after event #{inspect event}. Skipped process_event"
    end
  end


  def handle_info {_pid, {:fs, :file_event}, {path, event}}, state do
    path = path |> IO.iodata_to_binary
    if Regex.match? ~r/.*-[a-zA-Z]{4,}$/, path do # handle temporary/ uwanted files
      Logger.debug "#{path} matches temp file name! Skipping"
    else
      Logger.debug "Handling event for path: #{path}"
      process_event event, path
    end
    {:noreply, state}
  end


end
