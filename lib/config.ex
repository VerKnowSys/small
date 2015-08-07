defmodule Cfg do
  require Logger


  @doc """
  Returns application version
  """
  def version app_name \\ :small do
    {:ok, info} = :application.get_all_key app_name
    List.to_string info[:vsn]
  end


  @doc """
  Returns user helper binary to hack sessions launched under tmux
  """
  def user_helper do
    Application.get_env :small, :user_helper
  end


  @doc """
  Returns local POSIX username from ENV
  """
  def user do
    System.get_env "USER"
  end


  @doc """
  Returns filesystem check interval (for Sftp)
  """
  def interval do
    Application.get_env :small, :fs_check_interval
  end


  @doc """
  Returns ssh connection timeout
  """
  def ssh_connection_timeout do
    Application.get_env :small, :ssh_connection_timeout
  end


  @doc """
  Returns sftp buffer size
  """
  def sftp_buffer_size do
    Application.get_env :small, :sftp_buffer_size
  end



  @doc """
  Returns user specific configuration from global module configuration
  """
  def config do
    Application.get_env(:small, :config)[user]
  end


  @doc """
  Performs configuration check
  """
  def config_check do
    Logger.debug "Performing config check"
    [
      :username,
      :hostname,
      :ssh_port,
      :address,
      :remote_path
    ]
    |> Enum.each fn e ->
      cond do
        config[e] == nil ->
          raise "Missing configuration value: #{e}!"

        config[e] == "" ->
          raise "Required configuration value: #{e} is empty!"

        config[e] == 0 ->
          raise "Required configuration value: #{e} is zero!"

        true ->
          Logger.debug "Config check passed for #{e}[#{config[e]}]"
      end
    end
  end


  def log_level level \\ :debug do
    env = System.get_env "MIX_ENV"
    if env do
      Logger.info "Changing log level to: #{level} for environment: #{env}"
    else
      Logger.info "Changing log level to: #{level}"
    end
    Logger.configure [level: level]
    Logger.configure_backend :console, [level: level]
  end


end
