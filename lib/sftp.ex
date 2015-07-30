defmodule Sftp do
  use GenServer
  require Logger

  alias :ssh, as: SSH
  alias :ssh_sftp, as: SFTP
  alias :timer, as: Timer


  def hostname, do: "verknowsys.com"
  def username, do: "dmilith"
  def ssh_key_pass, do: ""
  def port, do: 60022


  ## Client API
  def start_link opts \\ [] do
    GenServer.start_link __MODULE__, :ok, [name: __MODULE__] ++ opts
  end


  def add do
    GenServer.call __MODULE__, :add, :infinity
  end


  ## Callbacks (Server API)
  def init :ok do
    SSH.start
    connection = SSH.connect String.to_char_list(hostname), port, [user: String.to_char_list(username), user_interaction: false, rsa_pass_phrase: String.to_char_list(ssh_key_pass), silently_accept_hosts: true, connect_timeout: 5000]

    case connection do
      {:ok, conn} ->
        Logger.info "Connected to SSH server"
        # elements_amount = length QueueAgent.get_all
        # Logger.debug "QueueAgent state - #{elements_amount}"
        # Stream.repeatedly(fn ->
        #   Logger.debug "Running unfinished tasks (#{elements_amount})"
        #   add
        # end) |> Enum.take elements_amount
        # Logger.debug "Done"
        {:ok, conn}

      {:error, err} ->
        Logger.error "Error connecting to SSH: #{inspect err}"
        {:error, err}
    end
  end


  def handle_call :add, _from, ssh_connection do
    time = Timer.tc fn ->
      case QueueAgent.first do
        {:add, local_file, remote_dest_file} ->
          if File.exists?(local_file) and File.regular?(local_file) do
            Logger.info "Handling synchronous task to put file: #{local_file} to remote: #{hostname}:#{remote_dest_file}"
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
                        Notification.send "Error streaming file #{local_file}!"
                        raise "Error streaming file: #{local_file}: #{inspect x}"
                    end
                    Logger.debug "Closing channel: #{inspect channel}"
                    SFTP.close channel, handle
                    SFTP.stop_channel channel
                    QueueAgent.remove {:add, local_file, remote_dest_file}

                  {:error, err} ->
                    Logger.error "Error opening file for writing: #{inspect err}"
                end

              {:error, err} ->
                Notification.send "Error creating SFTP channel!"
                raise "Error creating SFTP channel: #{inspect err}"
            end
          else
            Logger.error "Local file not found or not a regular file: #{local_file}!"
          end

        :empty ->
          Logger.info "Empty queue. Ignoring request"
      end
    end

    case time do
      {elapsed, _} ->
        Logger.info "Elapsed: #{elapsed/1000}ms"
        Logger.debug "Queue elements left: #{QueueAgent.get_all}"
    end

    {:reply, ssh_connection, ssh_connection}
  end

end
