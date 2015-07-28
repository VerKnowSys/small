defmodule Sftp do
  use GenServer
  require Logger

  alias :ssh, as: SSH


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


  def handle_call({:add, path_to_file}, _from, ssh_connection) do
    Logger.info "Handling synchronous task to put file: #{path_to_file} to remote: #{hostname}"
    {:reply, ssh_connection, ssh_connection}
  end

end
