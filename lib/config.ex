defmodule Cfg do
  require Logger

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
    Application.get_env :syncemall, :fs_check_interval
  end


  @doc """
  Returns ssh connection timeout
  """
  def ssh_connection_timeout do
    Application.get_env :syncemall, :ssh_connection_timeout
  end


  @doc """
  Returns sftp buffer size
  """
  def sftp_buffer_size do
    Application.get_env :syncemall, :sftp_buffer_size
  end



  @doc """
  Returns user specific configuration from global module configuration
  """
  def config do
    Application.get_env(:syncemall, :config)[user]
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


end
