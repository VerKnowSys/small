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
  Returns user specific configuration from global module configuration
  """
  def config do
    Application.get_env(:syncemall, :config)[user]
  end

end
