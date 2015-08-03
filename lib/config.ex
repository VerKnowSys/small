defmodule Cfg do

  def user do
    System.get_env "USER"
  end

  def config do
    Application.get_env(:syncemall, :config)[user]
  end

end
