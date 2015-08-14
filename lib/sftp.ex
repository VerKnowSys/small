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
    GenServer.call __MODULE__, :add, :infinity
  end


  def do_exception do
    GenServer.call __MODULE__, :do_exception, :infinity
  end


  def launch_interval_check do
    info "Starting queue check with check interval: #{interval}ms"
    Timer.apply_interval interval, Sftp, :add, []
  end


  ## Callbacks (Server API)
  def init :ok do
    notice "Launching Sftp client"
    SSH.start
    connection = SSH.connect String.to_char_list(config[:hostname]), config[:ssh_port],
      [user: String.to_char_list(config[:username]),
       user_interaction: false,
       rsa_pass_phrase: String.to_char_list(config[:ssh_key_pass]),
       silently_accept_hosts: true,
       connect_timeout: ssh_connection_timeout
      ], ssh_connection_timeout

    case connection do
      {:ok, conn} ->
        notice "Connected to SSH server"
        {:ok, _} = launch_interval_check
        {:ok, conn}

      {:error, err} ->
        error "Error connecting to SSH: #{inspect err}"
        {:error, err}
    end
  end


  def size_kib size_in_bytes do
    Float.round size_in_bytes / 1024, 2
  end


  def stream_file_to_remote channel, handle, local_file, local_size do
    try do
      notice "Streaming file of size: #{size_kib local_size}KiB to remote server.."
      chunks = div local_size, sftp_buffer_size
      debug "Chunks: #{chunks}"
      (File.stream! local_file, [:read], sftp_buffer_size)
        |> Enum.with_index |> (Enum.each fn {chunk, index} ->
          chunks_percent = if chunks == 0, do: 100.0, else: index * 100 / chunks
          percent = Float.round chunks_percent, 2
          IO.write "\rProgress: #{percent}% "
          SFTP.write channel, handle, chunk, sftp_write_timeout
        end)
      notification "Uploaded successfully.", :upload
    catch
      x ->
        SSH.stop
        notification "Error streaming file #{local_file}: #{inspect x}!", :error
    end
  end


  @spec send_file(ssh_connection :: String.t, local_file :: String.t, remote_dest_file :: String.t) :: any
  def send_file ssh_connection, local_file, remote_dest_file do
    debug "Starting ssh channel.."
    a_channel = SFTP.start_channel ssh_connection, [blocking: false, pull_interval: 2, timeout: sftp_start_channel_timeout]
    case a_channel do
      {:ok, channel} ->
        remote_dest_file = remote_dest_file |> String.to_char_list
        remote_handle = SFTP.read_file_info channel, remote_dest_file
        debug "Started channel: #{inspect channel} for file: #{remote_dest_file}"

        a_handle = SFTP.open channel, remote_dest_file, [:write], sftp_open_channel_timeout
        case a_handle do
          {:ok, handle} ->
            case File.stat local_file do
              {:ok, file_info} ->
                case file_info do
                  %File.Stat{access: _, atime: _, ctime: _, gid: _, inode: _, links: _, major_device: _, minor_device: _, mode: _, mtime: _, size: local_size, type: :regular, uid: _} ->
                    debug "Checking remote file #{remote_dest_file}"
                    case remote_handle do
                      {:ok, remote_file_info} ->
                        debug "Remote file info insight: #{inspect remote_file_info} of file: #{remote_dest_file}"
                        case remote_file_info do
                          {:file_info, size, :regular, _, _, _, _, _, _, _, _, _, _, _} ->
                            debug "Local size: #{local_size}KiB, remote size: #{size}KiB"
                            cond do
                              size > 0 ->
                                if size != local_size do
                                  info "Found non empty remote file. Uploading file to remote"
                                  stream_file_to_remote channel, handle, local_file, local_size
                                else
                                  info "Remote file size equals local file size. File already uploaded. File upload skipped."
                                end

                              size == 0 ->
                                debug "Remote file empty"
                                stream_file_to_remote channel, handle, local_file, local_size
                            end

                          {:error, :no_such_file} ->
                            debug "No remote file"
                            stream_file_to_remote channel, handle, local_file, local_size
                        end

                      {:error, _reason} ->
                        debug "No remote file: #{remote_dest_file}, reason: #{_reason}"
                        stream_file_to_remote channel, handle, local_file, local_size
                    end
                end

              {_, reason} ->
                error "Error reading local file stats of file: #{local_file}: #{inspect reason}"
            end

            debug "Closing file handle"
            SFTP.close channel, handle
            debug "Closing channel: #{inspect channel}"
            SFTP.stop_channel channel

          {:error, err} ->
            error "Error opening file for writing: #{inspect err}"
        end

      {:error, err} ->
        SSH.stop
        notification "Error creating SFTP channel: #{inspect err}!", :error
    end
  end


  @doc """
  Adds clipboard items to persistent history
  """
  def add_to_history local_file do
    to_history_entry = Clipboard.get
    to_history = String.strip Regex.replace ~r/\n/, to_history_entry, " "
    debug "Putting content: '#{to_history}' to history of local file: #{local_file}"
    DB.add to_history, local_file
  end


  @doc """
  Creates content which will be copied to clipboard as http links
  """
  def build_clipboard do
    clip_time = Timer.tc fn ->
      first = QueueAgent.first
      cond do
        (length QueueAgent.get_all) > 1 ->
          debug "More than one entry found in QueueAgent, merging results"
          QueueAgent.get_all
            |> (Enum.map fn elem ->
              {_, file_path, _, uuid} = elem
              config[:address] <> uuid <> "." <> List.last String.split file_path, "."
            end)
            |> Enum.join("\n")
            |> Clipboard.put

        first != :empty ->
          case first do
            {_, file_path, _, uuid} ->
              debug "Single entry found in QueueAgent, copying to clipboard"
              extension = if (String.contains? file_path, "."), do: "." <> (List.last String.split file_path, "."), else: ""
              Clipboard.put config[:address] <> uuid <> extension

            :empty ->
              debug "Skipping copying to clipboard, empty queue"
          end

        true ->
          debug "Clipboard build skipped"

      end
    end
    case clip_time do
      {_elapsed, _} ->
        debug "Clipboard routine done in: #{_elapsed/1000}ms"
        :ok
    end
  end


  def handle_call :do_exception, _from, _ssh_connection do
    raise "An exception!"
  end


  def handle_call :add, _from, ssh_connection do
    unless Enum.empty? QueueAgent.get_all do
      time = Timer.tc fn ->
        build_clipboard
        for element <- QueueAgent.get_all do
          case element do
            {:add, local_file, remote_dest_file, random_uuid} ->
              if File.exists?(local_file) and File.regular?(local_file) do
                extension = if (String.contains? local_file, "."), do: "." <> (List.last String.split local_file, "."), else: ""
                remote_dest = remote_dest_file <> extension
                notice "Handling synchronous task to put file: #{local_file} to remote: #{config[:hostname]}:#{remote_dest}"
                inner = Timer.tc fn ->
                  send_file ssh_connection, local_file, remote_dest
                end

                if (List.last QueueAgent.get_all) == element do
                  notice "Uploading last element, adding to history"
                  add_to_history local_file
                end

                case inner do
                  {elapsed, _} ->
                    info "Sftp file send elapsed: #{elapsed/1000}ms"
                end
              else
                error "Local file not found or not a regular file: #{local_file}!"
              end
              QueueAgent.remove {:add, local_file, remote_dest_file, random_uuid}

            :empty ->
              notice "Empty queue. Ignoring request"
          end
        end
      end

      case time do
        {_elapsed, _} ->
          debug "Whole operation finished in: #{_elapsed/1000}ms"
      end
    end
    {:reply, ssh_connection, ssh_connection}
  end

end
