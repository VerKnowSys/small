defmodule Cfg do
  require Lager
  import Lager

  alias :lager, as: LagerBackend


  defp app_env do
    case System.get_env "MIX_ENV" do
      "" ->
        "dev"
      a ->
        a
    end
  end
  def env, do: app_env
  def project_dir, do: System.get_env("HOME") <> "/Library/Small/" <> app_env
  def mnesia_dumps_dir, do: System.get_env("HOME") <> "/Library/Small/.mnesia-dumps-#{env}/"


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
  Returns interval between database dumps to disk. Default: 6h
  """
  def dump_interval do
    Application.get_env :small, :mnesia_autodump_interval
  end


  @doc """
  Returns ssh connection timeout
  """
  def ssh_connection_timeout do
    Application.get_env :small, :ssh_connection_timeout
  end


  @doc """
  Returns sftp start channel timeout
  """
  def sftp_start_channel_timeout do
    Application.get_env :small, :sftp_start_channel_timeout
  end


  @doc """
  Returns sftp open channel timeout
  """
  def sftp_open_channel_timeout do
    Application.get_env :small, :sftp_open_channel_timeout
  end


  @doc """
  Returns sftp buffer size
  """
  def sftp_buffer_size do
    Application.get_env :small, :sftp_buffer_size
  end


  @doc """
  Gets sftp chunk write timeout
  """
  def sftp_write_timeout do
    Application.get_env :small, :sftp_write_timeout
  end


  @doc """
  Gets webapi port for current mode
  """
  def webapi_port do
    case app_env do
      "prod" ->
        Application.get_env :small, :webapi_port

      "test" ->
        Application.get_env :small, :webapi_test_port

      _ ->
        Application.get_env :small, :webapi_dev_port

    end
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
    debug "Performing config check"
    [
      :username,
      :hostname,
      :ssh_port,
      :address,
      :remote_path
    ]
    |> (Enum.each fn e ->
      cond do
        config[e] == nil ->
          raise "Missing configuration value: #{e}!"

        config[e] == "" ->
          raise "Required configuration value: #{e} is empty!"

        config[e] == 0 ->
          raise "Required configuration value: #{e} is zero!"

        true ->
          debug "Config check passed for #{e}[#{config[e]}]"
      end
    end)
  end


  def log_level level \\ :debug do
    env = System.get_env "MIX_ENV"
    if env do
      notice "Changing log level to: #{level} for environment: #{env}"
    else
      notice "Changing log level to: #{level}"
    end
    LagerBackend.set_loglevel :lager_console_backend, level
  end


  def get_initial_log_level do
    result = System.get_env "MIX_ENV"
    cond do
      result == "dev" ->
        :debug

      result == nil ->
        :info

      result == "prod" ->
        :notice

      result == "test" ->
        :warn
    end
  end


  def ssh_opts do
    [
      user: (String.to_char_list config[:username]),
      user_interaction: false,
      rsa_pass_phrase: (String.to_char_list config[:ssh_key_pass]),
      silently_accept_hosts: true,
      # connect_timeout: ssh_connection_timeout,
      # idle_time: ssh_connection_timeout
    ]
  end


  def set_default_mnesia_dir data_dir do
    :application.set_env :mnesia, :dir, to_char_list data_dir
  end

end
