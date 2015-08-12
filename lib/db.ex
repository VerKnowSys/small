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
      [:ok, :ok, :ok] ->
        notice "Database created for node #{inspect node}"
        Amnesia.transaction do
          notice "Adding default user"
          %User{name: Cfg.user} |> User.write
        end

      [error: {:already_exists, _}, error: {:already_exists, _}, error: {:already_exists, _}] ->
        debug "Database already created"

      [error: {:bad_type, _, :disc_only_copies, _}, error: {:bad_type, _, :disc_only_copies, _}, error: {:bad_type, _, :disc_only_copies, _}] ->
        warning "Found an issue with bad_type of requested - disk_only mode. Recovering.."
        destroy
        init_and_start

      [error: err, error: err, error: err] ->
        critical "Database creation failure: #{inspect err}"

      err ->
        critical "Database creation failure: #{inspect err}"
    end

    # time = Timer.tc fn ->
    #   max = 50_000
    #   info "Adding #{max} user records"
    #   Amnesia.transaction do
    #     for i <- 0..max do
    #       user = %User{name: "John#{i}"} |> User.write
    #       user |> User.add_history "History of user #{i}"
    #     end
    #   end
    # end

    # case time do
    #   {_elapsed, _} ->
    #     notice "Add user records done in: #{_elapsed/1000}ms"
    #     :ok
    # end
  end


  defp destroy_schema do
    warning "Stopping and destroying Amnesia schema"
    Amnesia.stop
    Amnesia.Schema.destroy
  end


  def destroy do
    warning "Destroying database"
    Database.destroy
    destroy_schema
  end


  def close do
    warning "Shutting down"
    Amnesia.stop
  end


  def add link do
    Amnesia.transaction do
      selection = User.where name == Cfg.user
      user = selection |> Amnesia.Selection.values |> List.first
      user |> User.add_history String.strip link
    end
  end


  def get_history do
    Amnesia.transaction do
      selection = User.where name == Cfg.user
      user = selection |> Amnesia.Selection.values |> List.first

      (History.where user_id == user.id)
        |> Amnesia.Selection.values
        |> (Enum.sort fn e1, e2 -> e1.timestamp > e2.timestamp end)
        |> Enum.map fn entry ->
        "#{entry.timestamp} - #{entry.content}"
      end
    end
  end


end
