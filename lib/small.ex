defmodule Small do
  require Lager
  import Lager
  use GenServer
  import Cfg

  alias :fs, as: FS


  ## Client API
  def start_link opts \\ [] do
    notice "Launching Small Filesystem Handler"
    GenServer.start_link __MODULE__, :ok, [name: __MODULE__] ++ opts
  end


  def init :ok do
    FS.subscribe
    notice "Filesystem events watcher initialized"
    {:ok, self}
  end


  def start :normal, [] do
    start_link
  end


  def process_event event, file_path do
    if File.exists? file_path do
      debug "Handling event: #{inspect event} for path #{file_path}"
      random_uuid = UUID.uuid3 nil, file_path, :hex
      remote_dest_file = "#{config[:remote_path]}#{random_uuid}"
      Queue.put %Database.Queue{user_id: DB.user.id, local_file: file_path, remote_file: remote_dest_file, uuid: random_uuid}
      Sftp.add
    else
      debug "File doesn't exists: #{file_path} after event #{inspect event}. Skipped process_event"
    end
  end


  def handle_info {_pid, {:fs, :file_event}, {path, event}}, state do
    path = path |> IO.iodata_to_binary
    debug "Handling event for path: #{path}"
    process_event event, path
    {:noreply, state}
  end


end
