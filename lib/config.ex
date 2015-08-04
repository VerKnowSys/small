defmodule Cfg do

  def user do
    System.get_env "USER"
  end


  @doc """
  Returns filesystem check interval (for Sftp)
  """
  def interval do
    Application.get_env :syncemall, :fs_check_interval
  end


  def config do
    Application.get_env(:syncemall, :config)[user]
  end

end
