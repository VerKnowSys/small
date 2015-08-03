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


  def process_event file_path do
    random_uuid = UUID.uuid4
    unless config[:username] do
      raise "Unknown user #{config.user} for ConfigAgent. Define your user and settings first!"
    end
    link = "#{config[:address]}#{random_uuid}.png"
    remote_dest_file = "#{config[:remote_path]}#{random_uuid}.png"

    QueueAgent.put {:add, file_path, remote_dest_file, random_uuid}
    Logger.info "Link copied to clipboard: #{link}"
    Logger.debug "Adding an element to queue (#{file_path} -> #{remote_dest_file})"
    Sftp.add
    Notification.send "Link synchronized: #{link}"
  end


  def handle_info({_pid, {:fs, :file_event}, {path, event}}, _socket) do
    if event == [:renamed, :xattrmod] do
      Logger.debug "Handling event: #{inspect event}"
      process_event path
    else
      Logger.debug "Unhandled event: #{inspect event}"
    end
    {:noreply, {path, event}}
  end
end
