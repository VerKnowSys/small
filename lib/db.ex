defmodule DB do
  @moduledoc """
  Database Backend module.
  """

  require Lager
  import Lager
  use Database
  use Amnesia


  def create_amnesia_schema do
    Amnesia.stop
    case Amnesia.Schema.create do
      :ok ->
        notice "Amnesia Schema created"

      {:error, {_, {:already_exists, a_node}}} ->
        notice "Amnesia schema already created for node: #{a_node}"

      {:error, {_, {err, a_node}}} ->
        critical "Amnesia schema cannot be created for a_node: #{a_node} cause: #{inspect err}"

      _ ->
        notice "Wildcard!!"
    end
  end


  defp commit_creation a_node do
    notice "Database created for node #{inspect a_node}"
    Amnesia.transaction do
      notice "Adding default user"
      %User{name: Cfg.user} |> User.write
    end
  end


  defp create_node_if_necessary do
    case Database.create disk!: [node] do
      [:ok, :ok, :ok, :ok] ->
        debug "Creating node: #{inspect node}"
        commit_creation node

      [error: {:already_exists, _}, error: {:already_exists, _}, error: {:already_exists, _}, error: {:already_exists, _}] ->
        debug "Database already created."

      [error: {:bad_type, _, :disc_only_copies, _}, error: {:bad_type, _, :disc_only_copies, _}, error: {:bad_type, _, :disc_only_copies, _}, error: {:bad_type, _, :disc_only_copies, _}] ->
        critical "Found an issue with bad_type of requested - disk_only mode. Recovering.."
        # destroy
        # init_and_start

      err ->
        critical "Database creation failure: #{inspect err}"
    end
  end


  def init_and_start do
    Amnesia.stop
    File.mkdir_p Cfg.project_dir
    create_amnesia_schema
    Amnesia.start
    debug "Schema dump:\n#{Amnesia.Schema.print}"
    create_node_if_necessary
  end


  def dump_mnesia param \\ "" do
    File.mkdir_p Cfg.mnesia_dumps_dir
    case param do
      "" ->
        dump_db_file Timestamp.now |> (String.replace ~r/[:. ]/, "-")
      a_name ->
        dump_db_file a_name
    end
  end


  def dump_db_file tstamp do
    dump_name = "#{Cfg.mnesia_dumps_dir}mnesia-db.#{tstamp}.erl"
    notice "Dumping database to file: #{dump_name}"
    Amnesia.dump "#{dump_name}"
  end


  defp destroy_schema do
    warning "Stopping and destroying Amnesia schema"
    Amnesia.stop
    Amnesia.Schema.destroy
  end


  def destroy do
    warning "Destroying database"
    list = Database.destroy
    debug "Destroyed: #{inspect list}"
    destroy_schema
  end


  def close do
    warning "Shutting down"
    Amnesia.stop
  end


  @doc """
  Helper to get user struct from Mnesia
  """
  def user do
    Amnesia.transaction do
      selection = User.where name == Cfg.user
      selection |> Amnesia.Selection.values |> List.first
    end
  end


  @doc """
  Adds link to user history
  """
  def add_history history do
    Amnesia.transaction do
      user |> (User.add_history history)
    end
  end


  @doc """
  Gets current queue state from Mnesia
  """
  def get_queue do
    Amnesia.transaction do
      queue = user |> User.queue
      case queue do
        nil ->
          []
        _any ->
          queue
      end
    end
  end


  def add_to_queue record do
    Amnesia.transaction do
      user |> (User.add_to_queue record)
    end
  end


  def remove_from_queue record do
    Amnesia.transaction do
      user |> (User.remove_from_queue record)
    end
  end


  def get_history do
    Amnesia.transaction do
      # debug "get_history - user: #{inspect user}, histories: #{inspect user |> User.histories |> Enum.take 5}"
      # NOTE: slower but more expressie way:
      # (History.where user_id == user.id)
      # |> Amnesia.Selection.values
      #
      # or:
      user |> User.histories
        |> (Enum.sort fn e1, e2 -> e1.timestamp > e2.timestamp end)
        |> (Enum.map fn entry ->
                %Database.History{user_id: entry.user_id, timestamp: entry.timestamp, content: entry.content, file: entry.file, uuid: entry.uuid}
              end)
    end
  end


end
