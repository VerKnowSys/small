defmodule DB do
  @moduledoc """
  Database Backend module.
  """

  require Lager
  import Lager
  use Database
  use Amnesia


  def init_and_start do
    case Amnesia.Schema.create do
      :ok ->
        notice "Amnesia Schema created"

      {:error, {_, {:already_exists, node}}} ->
        debug "Amnesia schema already created for node: #{node}"

      {:error, {_, {err, node}}} ->
        critical "Amnesia schema cannot be created for node: #{node} cause: #{inspect err}"
    end

    notice "Starting Amnesia"
    Amnesia.start

    case Database.create disk!: [node] do
      [:ok, :ok, :ok, :ok] ->
        notice "Database created for node #{inspect node}"
        Amnesia.transaction do
          notice "Adding default user"
          %User{name: Cfg.user} |> User.write
        end

      [error: {:already_exists, _}, error: {:already_exists, _}, error: {:already_exists, _}, error: {:already_exists, _}] ->
        debug "Database already created"

      [error: {:bad_type, _, :disc_only_copies, _}, error: {:bad_type, _, :disc_only_copies, _}, error: {:bad_type, _, :disc_only_copies, _}, error: {:bad_type, _, :disc_only_copies, _}] ->
        warning "Found an issue with bad_type of requested - disk_only mode. Recovering.."
        destroy
        init_and_start

      [error: err, error: err, error: err, error: err] ->
        critical "Database creation failure: #{inspect err}"

      err ->
        critical "Database creation failure: #{inspect err}"
    end
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
  def add history do
    Amnesia.transaction do
      user |> User.add_history history
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
      user |> User.add_to_queue record
    end
  end


  def remove_from_queue record do
    Amnesia.transaction do
      user |> User.remove_from_queue record
    end
  end


  def get_history do
    Amnesia.transaction do
      debug "get_history - user: #{inspect user}, histories: #{inspect user |> User.histories |> Enum.take 5}"
      # NOTE: slower but more expressie way:
      # (History.where user_id == user.id)
      # |> Amnesia.Selection.values
      #
      # or:
      user |> User.histories
        |> (Enum.sort fn e1, e2 -> e1.timestamp > e2.timestamp end)
        |> Enum.map fn entry ->
        %Database.History{user_id: entry.user_id, timestamp: entry.timestamp, content: entry.content, file: entry.file, uuid: entry.uuid}
      end
    end
  end


end
