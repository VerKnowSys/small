defmodule Sftp do
  use GenServer
  require Logger

  alias :ssh, as: SSH
  alias :ssh_connection, as: SSHConnection
  alias :ssh_sftp, as: SFTP


  def hostname, do: "verknowsys.com"
  def port, do: 60022


  ## Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end


  def add(server, path_to_file) do
    GenServer.call(server, {:add, path_to_file})
  end


  ## Callbacks (Server API)
  def init(:ok) do
    SSH.start
    connection = SSH.connect String.to_char_list(hostname), port, [user_interaction: false, silently_accept_hosts: true, connect_timeout: 5000]

    case connection do
      {:ok, conn} ->
        Logger.info "Connected to SSH server"
        {:ok, conn}

      {:error, err} ->
        Logger.error "Error connecting to SSH: #{inspect err}"
        {:error, err}
    end
  end


  def handle_call({:add, remote_dest_file}, _from, ssh_connection) do
    Logger.info "Handling synchronous task to put file: #{remote_dest_file} to remote: #{hostname}"
    a_session = SSHConnection.session_channel ssh_connection, :infinity

    case a_session do
      {:ok, session} ->
        a_channel = SFTP.start_channel ssh_connection
        case a_channel do
          {:ok, channel} ->
            Logger.info "Started channel: #{inspect channel}"
            a_handle = SFTP.open channel, String.to_char_list(remote_dest_file), [:write]
            case a_handle do
              {:ok, handle} ->
                Logger.debug "Got handle: #{inspect handle}"
                SFTP.awrite channel, handle, "dane o" # TODO: write real data from local filesystem instead of this
                SFTP.stop_channel channel
                SFTP.close channel, handle

              {:error, err} ->
                Logger.error "Error opening file for writing: #{inspect err}"
            end

          {:error, err} ->
            Logger.error "Error creating SFTP channel"
        end

        Logger.info "Closing session: #{inspect session}"
        SSHConnection.close ssh_connection, session

      {:error, err} ->
        Logger.error "Failed to create SSH session: #{inspect err}"
    end

    {:reply, ssh_connection, ssh_connection}
  end

end
