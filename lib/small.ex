defmodule Small do
  require Logger
  use GenServer
  import Cfg

  alias :fs, as: FS


  ## Client API
  def start_link opts \\ [] do
    Logger.info "Launching Small"
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
    Logger.debug "Handling event: #{inspect event} for path #{file_path}"
    unless config[:username] do
      raise "Unknown user #{config.user} for ConfigAgent. Define your user and settings first!"
    end
    random_uuid = UUID.uuid3 nil, file_path, :hex
    remote_dest_file = "#{config[:remote_path]}#{random_uuid}"
    record = {:add, file_path, remote_dest_file, random_uuid}
    Logger.debug "#{inspect record}"
    QueueAgent.put record
    Sftp.add
  end


  def handle_info {pid, {:fs, :file_event}, {path, event}}, state do
    path = path |> List.to_string
    case event do
      [:renamed, :xattrmod] ->
        process_event event, path

      [:created, :removed, :inodemetamod, :modified, :finderinfomod, :changeowner, :xattrmod] ->
        process_event event, path

      [:created, :inodemetamod, :modified, :finderinfomod, :changeowner, :xattrmod] ->
        process_event event, path

      [:created, :modified, :xattrmod] ->
        process_event event, path

      _ ->
        Logger.debug "Unhandled event: #{inspect event} for path #{path} of pid #{inspect pid}"

    end
    {:noreply, state}
  end


end