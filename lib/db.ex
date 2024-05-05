defmodule DB do
  @moduledoc """
  Database Backend module.
  """

  require Logger
  require Exquisite
  alias Database
  use Database
  use Amnesia

  @spec create_amnesia_schema() :: :ok
  def create_amnesia_schema do
    Amnesia.stop()

    case Amnesia.Schema.create() do
      :ok ->
        Logger.info("Amnesia Schema created")

      {:error, {_, {:already_exists, a_node}}} ->
        Logger.info("Amnesia schema already created for node: #{a_node}")

      {:error, {_, {err, a_node}}} ->
        Logger.error(
          "CRIT: Amnesia schema cannot be created for a_node: #{a_node} cause: #{inspect(err)}"
        )

      _ ->
        Logger.info("Wildcard!!")
    end
  end

  defp create_node_if_necessary do
    case Database.create(disk!: [node()]) do
      [
        :ok,
        :ok,
        :ok
      ] ->
        Logger.debug("Creating node: #{inspect(node())}")
        Logger.info("Database created for node #{inspect(node())}")

      [
        error: {:already_exists, _},
        error: {:already_exists, _},
        error: {:already_exists, _}
      ] ->
        Logger.debug("Database already created.")

      [
        error: {:bad_type, _, :disc_only_copies, _},
        error: {:bad_type, _, :disc_only_copies, _},
        error: {:bad_type, _, :disc_only_copies, _}
      ] ->
        Logger.error(
          "CRIT: Found an issue with bad_type of requested - disk_only mode. Recovering.."
        )

      # destroy
      # init_and_start

      err ->
        Logger.error("CRIT: Database creation failure: #{inspect(err)}")
    end
  end

  @spec init_and_start() :: :ok
  def init_and_start do
    Amnesia.stop()
    File.mkdir_p(Cfg.project_dir())
    create_amnesia_schema()
    Amnesia.start()
    create_node_if_necessary()
  end

  @spec dump_mnesia() :: any()
  @spec dump_mnesia(charlist()) :: any()
  def dump_mnesia(param \\ "") do
    File.mkdir_p(Cfg.mnesia_dumps_dir())

    case param do
      "" ->
        dump_db_file(Timestamp.now() |> String.replace(~r/[:. ]/, "-"))

      a_name ->
        dump_db_file(a_name)
    end
  end

  @spec dump_db_file(charlist()) :: :ok
  def dump_db_file(tstamp) do
    dump_name = "#{Cfg.mnesia_dumps_dir()}mnesia-db.#{tstamp}.erl"
    Logger.info("Dumping database to file: #{dump_name}")
    Amnesia.dump("#{dump_name}")
    :ok
  end

  defp destroy_schema do
    Logger.warning(" Stopping and destroying Amnesia schema")
    Amnesia.stop()
    Amnesia.Schema.destroy()
  end

  @spec destroy() :: :ok | {:error, any()}
  def destroy do
    Logger.warning(" Destroying database")
    list = Database.destroy()
    Logger.debug("Destroyed: #{inspect(list)}")
    destroy_schema()
  end

  @spec close() :: :stopped
  def close do
    Logger.warning(" Shutting down")
    Amnesia.stop()
  end

  @spec histories() :: any()
  def histories do
    hist = Amnesia.Selection.values(History.where(timestamp != -1))

    case hist do
      nil ->
        []

      hists ->
        hists
    end
  end

  @doc """
  Adds link to user history
  """
  @spec add_history(History.t()) :: :ok
  def add_history(history) do
    Amnesia.transaction do
      History.write(history)
    end

    :ok
  end

  @doc """
  Gets current queue state from Mnesia
  """
  @spec get_queue() :: Enum.t()
  def get_queue do
    Amnesia.transaction do
      queue = Queue.first()

      case queue do
        nil ->
          []

        _any ->
          queue
      end
    end
  end

  @spec add_to_queue(Queue.t()) :: :ok
  def add_to_queue(record) do
    Amnesia.transaction do
      Queue.write(record)
    end

    :ok
  end

  @spec remove_from_queue(Queue.t()) :: :ok
  def remove_from_queue(record) do
    Amnesia.transaction do
      Queue.delete(record)
    end

    :ok
  end

  @spec get_history() :: Enum.t()
  def get_history do
    Amnesia.transaction do
      DB.histories()
      |> Enum.sort(fn e1, e2 -> e1.timestamp > e2.timestamp end)
      |> Enum.map(fn entry ->
        %Database.History{
          timestamp: entry.timestamp,
          content: entry.content,
          file: entry.file,
          uuid: entry.uuid
        }
      end)
    end
  end
end
