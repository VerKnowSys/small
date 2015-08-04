defmodule SyncEmAll do
  require Logger
  use GenServer
  import Cfg

  alias :fs, as: FS


  ## Client API
  def start_link opts \\ [] do
    Logger.info "Launching SyncEmAll"
    GenServer.start_link __MODULE__, :ok, [name: __MODULE__] ++ opts
  end


  def init :ok do
    fsev = FS.subscribe
    {:ok, fsev}
  end


  def start :normal, [] do
    start_link
  end


  def process_event event, file_path do
    Logger.debug "Handling event: #{inspect event} for path #{file_path}"
    random_uuid = UUID.uuid4
    unless config[:username] do
      raise "Unknown user #{config.user} for ConfigAgent. Define your user and settings first!"
    end
    remote_dest_file = "#{config[:remote_path]}#{random_uuid}"
    QueueAgent.put {:add, file_path, remote_dest_file, random_uuid}
    Sftp.add
  end


  def handle_info {_pid, {:fs, :file_event}, {path, event}}, _socket do
    path = path |> List.to_string
    case event do
      [:renamed, :xattrmod] ->
        process_event event, path

      [:created, :removed, :inodemetamod, :modified, :finderinfomod, :changeowner, :xattrmod] ->
        process_event event, path

      [:created, :inodemetamod, :modified, :finderinfomod, :changeowner, :xattrmod] ->
        process_event event, path

      _ ->
        Logger.debug "Unhandled event: #{inspect event} for path #{path}"

    end
    {:noreply, {path, event}}
  end


end
