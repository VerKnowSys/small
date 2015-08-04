defmodule Sftp do
  use GenServer
  require Logger
  import Cfg

  alias :ssh, as: SSH
  alias :ssh_sftp, as: SFTP
  alias :timer, as: Timer


  ## Client API
  def start_link opts \\ [] do
    GenServer.start_link __MODULE__, :ok, [name: __MODULE__] ++ opts
  end


  def add do
    GenServer.call __MODULE__, :add, :infinity
  end


  def do_exception do
    GenServer.call __MODULE__, :exception, :infinity
  end

  ## Callbacks (Server API)
  def init :ok do
    SSH.start
    connection = SSH.connect String.to_char_list(config[:hostname]), config[:ssh_port],
      [user: String.to_char_list(config[:username]),
       user_interaction: false,
       rsa_pass_phrase: String.to_char_list(config[:ssh_key_pass]),
       silently_accept_hosts: true,
       connect_timeout: 5000
      ]

    case connection do
      {:ok, conn} ->
        Logger.info "Connected to SSH server"
        {:ok, conn}

      {:error, err} ->
        Logger.error "Error connecting to SSH: #{inspect err}"
        {:error, err}
    end
  end


  def send_file ssh_connection, local_file, remote_dest_file, random_uuid do
    a_channel = SFTP.start_channel ssh_connection
    case a_channel do
      {:ok, channel} ->
        Logger.debug "Started channel: #{inspect channel}"
        a_handle = SFTP.open channel, String.to_char_list(remote_dest_file), [:write]
        case a_handle do
          {:ok, handle} ->
            try do
              (File.stream! local_file, [:read], 131072)
                |> Enum.each fn chunk -> SFTP.write channel, handle, chunk, :infinity end
            catch
              x ->
                SSH.stop
                Notification.send "Error streaming file #{local_file}!"
                raise "Error streaming file: #{local_file}: #{inspect x}"
            end
            Logger.debug "Closing channel: #{inspect channel}"
            SFTP.close channel, handle
            SFTP.stop_channel channel
            QueueAgent.remove {:add, local_file, remote_dest_file, random_uuid}

          {:error, err} ->
            Logger.error "Error opening file for writing: #{inspect err}"
        end

      {:error, err} ->
        SSH.stop
        Notification.send "Error creating SFTP channel!"
        raise "Error creating SFTP channel: #{inspect err}"
    end
  end


  def handle_call :do_exception, _from, _ssh_connection do
    raise "An exception!"
  end


  def handle_call :add, _from, ssh_connection do
    time = Timer.tc fn ->
      if (length QueueAgent.get_all) > 1 do
        Logger.debug "More than one entry found in QueueAgent, merging results"
        QueueAgent.get_all
          |> Enum.map(fn elem ->
            {_, file_path, _, uuid} = elem
            extension = List.last String.split (List.to_string file_path), "."
            config[:address] <> uuid <> "." <> extension
          end)
          |> Enum.join("\n")
          |> Clipboard.put
      else
        Logger.debug "Single entry found in QueueAgent, copying to clipboard"
        {_, file_path, _, uuid} = QueueAgent.first
        extension = List.last String.split (List.to_string file_path), "."
        Clipboard.put config[:address] <> uuid <> "." <> extension
      end
      for element <- QueueAgent.get_all do
        case element do
          {:add, local_file, remote_dest_file, random_uuid} ->
            if File.exists?(local_file) and File.regular?(local_file) do
              extension = List.last String.split (List.to_string local_file), "."
              remote_dest = remote_dest_file <> "." <> extension
              Logger.info "Handling synchronous task to put file: #{local_file} to remote: #{config[:hostname]}:#{remote_dest}"
              inner = Timer.tc fn ->
                send_file ssh_connection, local_file, remote_dest, random_uuid
              end

              case inner do
                {elapsed, _} ->
                  Logger.info "Sftp file send elapsed: #{elapsed/1000}ms"

              end
            else
              Logger.error "Local file not found or not a regular file: #{local_file}!"
              QueueAgent.remove {:add, local_file, remote_dest_file, random_uuid}
            end

          :empty ->
            Logger.info "Empty queue. Ignoring request"
        end
      end
    end

    case time do
      {elapsed, _} ->
        Logger.info "Outer elapsed: #{elapsed/1000}ms"
    end

    {:reply, ssh_connection, ssh_connection}
  end

end
