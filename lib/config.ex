defmodule Cfg do
  require Logger


  defp data_dir_base do
    case :os.type() do
      {:unix, :darwin} -> "/Library/Small/"
      {:unix, _}       -> "/.small/"
    end
  end


  defp app_env do
    case System.get_env "MIX_ENV" do
      nil ->
        "prod"
      a ->
        a
    end
  end
  def env, do: app_env()
  def project_root_dir, do: System.get_env("HOME") <> data_dir_base()
  def project_dir, do: project_root_dir() <> env()
  def mnesia_dumps_dir, do: project_root_dir() <> ".mnesia-dumps-#{env()}/"


  @doc """
  Returns absolute path to default config file
  """
  @spec default_config_file :: String.t
  def default_config_file do
    project_root_dir() <> "/config.ex"
  end


  @doc """
  Returns application version
  """
  def version app_name \\ :small do
    {:ok, info} = :application.get_all_key app_name
    List.to_string info[:vsn]
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
  Returns default amount of history elements to load if not specified through http param
  """
  def amount_history_load do
    Application.get_env :small, :amount_history_load
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
    case app_env() do
      "dev" ->
        Application.get_env :small, :webapi_dev_port

      "test" ->
        Application.get_env :small, :webapi_test_port

      _ ->
        Application.get_env :small, :webapi_port

    end
  end




  @doc """
  Returns user specific configuration from dynamic configuration file
  """
  @spec config :: Keyword.t
  def config do
    case File.open default_config_file(), [:utf8] do
      {:ok, file} ->
        a_conf_file_string = Utils.read_file file
        {a_config, _} = Code.eval_string a_conf_file_string
        File.close file
        a_config

      {:error, cause} ->
        raise "Cannot open default config file: #{default_config_file()}. Reason: #{inspect cause}"
        []
    end
  end


  @doc """
  Performs configuration check
  """
  def config_check do
    Logger.info "Checking configuration…"
    unless File.exists? Cfg.default_config_file() do
      raise "No configuration file: #{Cfg.default_config_file()}"
    end

    Logger.debug "Performing config check"
    [
      :username,
      :hostname,
      :ssh_port,
      :address,
      :remote_path
    ]
    |> (Enum.each fn e ->
      cond do
        config()[e] == nil ->
          raise "Missing configuration value: #{e}!"

        config()[e] == "" ->
          raise "Required configuration value: #{e} is empty!"

        config()[e] == 0 ->
          raise "Required configuration value: #{e} is zero!"

        true ->
          Logger.debug "Config check passed for #{e}[#{config()[e]}]"
      end
    end)
  end


  def log_level level \\ :debug do
    Logger.configure [level: level]
    Logger.configure_backend :console, [level: level]
  end


  def get_initial_log_level do
    result = System.get_env "MIX_ENV"
    cond do
      result == "dev" || result == "" || result == nil ->
        :debug

      result == "prod" ->
        :info

      result == "test" ->
        :warn
    end
  end


  def ssh_opts do
    [
      user: (String.to_char_list config()[:username] || user()),
      user_interaction: false,
      rsa_pass_phrase: (String.to_char_list config()[:ssh_key_pass] || ""),
      silently_accept_hosts: true,
      # connect_timeout: ssh_connection_timeout,
      # idle_time: ssh_connection_timeout
    ]
  end


  def set_default_mnesia_dir data_dir do
    :application.set_env :mnesia, :dir, to_char_list data_dir
  end

end
