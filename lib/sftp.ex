defmodule Sftp do
  use GenServer
  require Lager
  import Lager
  import Cfg
  import Notification

  alias :ssh, as: SSH
  alias :ssh_sftp, as: SFTP
  alias :timer, as: Timer


  ## Client API
  def start_link opts \\ [] do
    GenServer.start_link __MODULE__, :ok, [name: __MODULE__] ++ opts
  end


  def add do
    GenServer.cast __MODULE__, :add
  end


  # def do_exception do
  #   GenServer.call __MODULE__, :do_exception, :infinity
  # end


  def launch_interval_check do
    info "Starting queue check with check interval: #{interval}ms"
    Timer.apply_interval interval, Sftp, :add, []
  end


  ## Callbacks (Server API)
  def init :ok do
    notice "Starting Sftp module"
    SSH.start
    launch_interval_check
    {:ok, self}
  end


  defp sftp_open_and_process_upload connection, local_file, remote_handle, remote_dest_file, channel do
    case SFTP.open channel, remote_dest_file, [:write], sftp_open_channel_timeout do
      {:ok, handle} ->
        local_size = Utils.read_size_of_file local_file
        remote_size = Utils.remote_file_size remote_handle
        debug "Local file: #{local_file} (#{local_size})"
        debug "Remote file: #{remote_dest_file} (#{remote_size})"
        cond do
          remote_size > 0 ->
            if remote_size != local_size do
              info "Found non empty remote file. Uploading file to remote"
              Utils.stream_file_to_remote channel, handle, local_file, local_size
            else
              info "Remote file size equal locals. File upload skipped."
            end

          remote_size == 0 ->
            debug "Remote file empty"
            Utils.stream_file_to_remote channel, handle, local_file, local_size
        end

        debug "Closing file handle"
        SFTP.close channel, handle
        debug "Closing channel: #{inspect channel}"
        SFTP.stop_channel channel
        debug "Closing SSH connection"
        SSH.close connection

      {:error, err} ->
        an_error = "Error opening write handle of remote file: #{inspect err}"
        notification an_error, :error
    end
  end


  defp process_ssh_connection connection, local_file, remote_dest_file do
    debug "Starting ssh channel for connection: #{inspect connection} for local file: #{local_file}"
    case SFTP.start_channel connection, [blocking: false, pull_interval: 2, timeout: sftp_start_channel_timeout] do
      {:ok, channel} ->
        remote_dest_file = remote_dest_file |> String.to_char_list
        remote_handle = SFTP.read_file_info channel, remote_dest_file
        debug "Started channel: #{inspect channel} for file: #{remote_dest_file}"
        sftp_open_and_process_upload connection, local_file, remote_handle, remote_dest_file, channel

      {:error, err} ->
        notification "Error creating SFTP channel: #{inspect err}!", :error
    end
  end


  def handle_cast {:send_file, local_file, remote_dest_file}, _ do
    debug "Starting ssh connection.."
    case (SSH.connect String.to_char_list(config[:hostname]), config[:ssh_port],
      [
        user: String.to_char_list(config[:username]),
        user_interaction: false,
        rsa_pass_phrase: String.to_char_list(config[:ssh_key_pass]),
        silently_accept_hosts: true,
        # connect_timeout: ssh_connection_timeout,
        # idle_time: ssh_connection_timeout
      ], ssh_connection_timeout) do

      {:ok, connection} ->
        debug "Processing connection with pid: #{inspect connection}"
        time = Timer.tc fn ->
          connection |> process_ssh_connection local_file, remote_dest_file
        end
        case time do
          {elapsed, _} ->
            debug "process_ssh_connection finished in: #{elapsed/1000}ms"
        end

      {:error, cause} ->
        error "Error caused by: #{inspect cause}"
    end

    {:noreply, self}
  end


  def handle_cast :add, _ do
    unless Enum.empty? Queue.get_all do
      time = Timer.tc fn ->
        build_clipboard
        for element <- Queue.get_all do
          case element do
            %Database.Queue{user_id: _, local_file: local_file, remote_file: remote_dest_file, uuid: random_uuid} ->
              if File.exists?(local_file) and File.regular?(local_file) do
                extension = if (String.contains? local_file, "."), do: "." <> (List.last String.split local_file, "."), else: ""
                remote_dest = remote_dest_file <> extension
                notice "Handling synchronous task to put file: #{local_file} to remote: #{config[:hostname]}:#{remote_dest}"
                send_file local_file, remote_dest

                debug "Comparing #{inspect List.last Queue.get_all} and #{inspect element}"
                if (List.last Queue.get_all) == element do
                  notice "Uploading last element, adding to history"
                  add_to_history local_file
                end

              else
                error "Local file not found or not a regular file: #{local_file}!"
              end

              record = %Database.Queue{user_id: DB.user.id, local_file: local_file, remote_file: remote_dest_file, uuid: random_uuid}
              debug "Removing from queue: #{inspect record}"
              Queue.remove record

            :empty ->
              notice "Empty queue. Ignoring request"
          end
        end
      end

      case time do
        {elapsed, _} ->
          debug "Whole operation finished in: #{elapsed/1000}ms"
      end
    end
    {:noreply, []}
  end


  @spec send_file(local_file :: String.t, remote_dest_file :: String.t) :: any
  def send_file local_file, remote_dest_file do
    GenServer.cast __MODULE__, {:send_file, local_file, remote_dest_file}
  end


  @doc """
  Adds clipboard items to persistent history
  """
  def add_to_history local_file do
    to_history = String.strip Regex.replace ~r/\n/, Clipboard.get, " "
    debug "Putting content: '#{to_history}' to history of local file: #{local_file}"
    DB.add_history %Database.History{user_id: DB.user.id, content: to_history, timestamp: Timestamp.now, file: local_file, uuid: (UUID.uuid4 :hex)}
  end


  defp create_queue_string collection do
    (Enum.map collection, fn an_elem ->
      case an_elem do
        %Database.Queue{user_id: _, local_file: file_path, remote_file: _, uuid: uuid} ->
          config[:address] <> uuid <> "." <> List.last String.split file_path, "."

        _ -> # :empty
          ""
      end
    end)
    |> Enum.join "\n"
  end


  @doc """
  Creates content which will be copied to clipboard as http links
  """
  def build_clipboard do
    clip_time = Timer.tc fn ->
      first = Queue.first
      cond do
        (length Queue.get_all) > 1 ->
          info "More than one entry found in QueueAgent, merging results"
          Queue.get_all
            |> create_queue_string
            |> Clipboard.put

        first ->
          (create_queue_string [first])
            |> Clipboard.put

      end
    end
    case clip_time do
      {elapsed, _} ->
        debug "Clipboard routine done in: #{elapsed/1000}ms"
        :ok
    end
  end


  # def handle_call :do_exception, _from, _ssh_connection do
  #   raise "An exception!"
  # end

end
