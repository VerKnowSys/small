defmodule Sftp do
  use GenServer
  require Logger
  import Cfg
  import Notification

  alias Database.Queue
  alias Database.History

  alias :ssh, as: SSH
  alias :ssh_sftp, as: SFTP
  alias :timer, as: Timer

  ## Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__] ++ opts)
  end

  @spec add() :: :ok
  def add do
    GenServer.cast(__MODULE__, :add)
  end

  @spec do_exception() :: any()
  def do_exception do
    GenServer.call(__MODULE__, :do_exception, :infinity)
  end

  @spec launch_interval_check() :: {:error, any()} | {:ok, :timer.tref()}
  def launch_interval_check do
    Logger.info("Starting queue check with check interval: #{interval()}ms")
    Timer.apply_interval(interval(), Sftp, :add, [])
  end

  ## Callbacks (Server API)
  @spec init(:ok) :: {:ok, pid()}
  def init(:ok) do
    Logger.info("Starting Sftp module")
    SSH.start()

    case launch_interval_check() do
      {:ok, pid} ->
        Logger.debug("Internal check spawned: #{inspect(pid)}")

      {:error, error} ->
        Logger.error("Internal check spawn failed with error: #{inspect(error)}")
    end

    {:ok, self()}
  end

  defp sftp_open_and_process_upload(
         connection,
         local_file,
         remote_handle,
         remote_dest_file,
         channel
       ) do
    case SFTP.open(channel, remote_dest_file, [:write], sftp_open_channel_timeout()) do
      {:ok, handle} ->
        local_size = Utils.local_file_size(local_file)
        remote_size = Utils.remote_file_size(remote_handle)

        Logger.debug(
          "Local file: #{local_file} (#{local_size}); Remote file: #{remote_dest_file} (#{remote_size})"
        )

        cond do
          remote_size <= 0 ->
            Logger.info("Found an empty remote file. Uploading file to remote")
            Utils.stream_file_to_remote(channel, handle, local_file, local_size)

          remote_size != local_size ->
            Logger.info("Local and remote files are different. Uploading file to remote")
            Utils.stream_file_to_remote(channel, handle, local_file, local_size)

          remote_size == local_size ->
            Logger.info("Found file of same size already uploaded. Skipping")
        end

        Logger.debug("Closing file handle, channel and ssh connection")
        SFTP.close(channel, handle)
        SFTP.stop_channel(channel)
        SSH.close(connection)

      {:error, err} ->
        notification("Error opening write handle of remote file: #{inspect(err)}", :error)
    end
  end

  defp process_ssh_connection(connection, local_file, remote_dest_file) do
    Logger.debug(
      "Starting ssh channel for connection: #{inspect(connection)} for local file: #{local_file}"
    )

    case SFTP.start_channel(connection,
           blocking: false,
           pull_interval: 20,
           timeout: sftp_start_channel_timeout()
         ) do
      {:ok, channel} ->
        remote_dest_file = remote_dest_file |> String.to_charlist()
        remote_handle = SFTP.read_file_info(channel, remote_dest_file)
        Logger.debug("Started channel: #{inspect(channel)} for file: #{remote_dest_file}")

        connection
        |> sftp_open_and_process_upload(local_file, remote_handle, remote_dest_file, channel)

      {:error, err} ->
        notification("Error creating SFTP channel: #{inspect(err)}!", :error)
    end
  end

  def handle_cast(:add, _) do
    queue = DB.get_queue()

    unless Enum.empty?(queue) do
      build_clipboard()

      queue
      |> Enum.map(fn element ->
        element |> process_element
      end)
    end

    {:noreply, self()}
  end

  def handle_cast({:send_file, local_file, remote_dest_file}, _) do
    case SSH.connect(
           String.to_charlist(config()[:hostname]),
           config()[:ssh_port],
           ssh_opts(),
           ssh_connection_timeout()
         ) do
      {:ok, connection} ->
        Logger.debug("Processing connection with pid: #{inspect(connection)}")

        time =
          Timer.tc(fn ->
            connection |> process_ssh_connection(local_file, remote_dest_file)
          end)

        case time do
          {elapsed, _} ->
            Logger.debug("process_ssh_connection finished in: #{elapsed / 1000}ms")
        end

      {:error, cause} ->
        Logger.error("Error caused by: #{inspect(cause)}")
    end

    {:noreply, self()}
  end

  defp process_element(element) do
    case element do
      %Queue{local_file: local_file, remote_file: remote_dest_file, uuid: random_uuid} ->
        a_queue = %Queue{
          local_file: local_file,
          remote_file: remote_dest_file,
          uuid: random_uuid
        }

        if File.exists?(local_file) and File.regular?(local_file) and
             not Regex.match?(~r/.*-[a-zA-Z]{4,}$/, local_file) do
          local_file |> send_file(remote_dest_file <> Utils.file_extension(local_file))
          a_queue |> add_to_history |> DB.remove_from_queue()
        else
          Logger.debug("Local file not found or not a regular file: #{local_file}. Skipping.")
          a_queue |> DB.remove_from_queue()
        end

      :empty ->
        Logger.info("Empty queue. Ignoring request")
    end
  end

  @spec send_file(local_file :: String.t(), remote_dest_file :: String.t()) :: any
  def send_file(local_file, remote_dest_file) do
    GenServer.cast(__MODULE__, {:send_file, local_file, remote_dest_file})
  end

  @doc """
  Adds clipboard items to persistent history
  """
  @spec add_to_history(Queue.t()) :: Queue.t()
  def add_to_history(queue) do
    to_history = config()[:address] <> queue.uuid <> Utils.file_extension(queue.local_file)

    a_history = %History{
      content: to_history,
      timestamp: Timestamp.now_unix(),
      file: queue.local_file,
      uuid: UUID.uuid4(:hex)
    }

    count =
      DB.get_history()
      |> Enum.filter(fn element ->
        String.contains?(element.content, to_history)
      end)
      |> Enum.count()

    if count == 0, do: DB.add_history(a_history)

    # pass queue structure further:
    queue
  end

  @spec create_queue_string(Enum.t()) :: String.t()
  def create_queue_string(collection) when is_list(collection) do
    Enum.map(collection, fn an_elem ->
      case an_elem do
        %Queue{local_file: file_path, remote_file: _, uuid: uuid} ->
          config()[:address] <> uuid <> Utils.file_extension(file_path)

        # :empty
        _ ->
          ""
      end
    end)
    |> Enum.join("\n")
  end

  def create_queue_string(_), do: ""

  @doc """
  Creates content which will be copied to clipboard as http links
  """
  @spec build_clipboard() :: :ok
  def build_clipboard do
    clip_time =
      Timer.tc(fn ->
        DB.get_queue()
        |> create_queue_string
        |> Clipboard.put()
      end)

    case clip_time do
      {elapsed, _} ->
        Logger.debug("Clipboard routine done in: #{elapsed / 1000}ms")
        :ok
    end
  end

  def handle_call(:do_exception, _from, _ssh_connection) do
    raise "An exception!"
  end
end
