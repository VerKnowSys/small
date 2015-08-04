defmodule Cfg do

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

end
