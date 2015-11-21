defmodule Small.Mixfile do
  use Mix.Project

  def project do
    [
      app: :small,
      version: "0.9.1",
      elixir: "~> 1.1",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      escript: escript,
      dialyzer: [
        paths: [
          "_build/dev/lib/small/ebin",
        ],
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      applications: applications,
      # mod: {SyncSupervisor, []}
    ]
  end


  defp mixenv do
    Atom.to_string Mix.env
  end


  def default_emu_args do
    "-smp enable -sname small#{mixenv}"
  end


  def escript do
    [
      main_module: SmallApplication,
      embed_elixir: true,
      language: :elixir,
      force: true,
      emu_args: default_emu_args
    ]
  end


  def applications do
    dev = [:exsync, :credo]
    prod = [:httpotion, :cowboy, :timex, :amnesia, :exlager, :uuid, :fs, :logger]
    case Mix.env do
      :prod ->
        prod
      _ ->
        dev ++ prod
    end
  end


  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      { :uuid, "~> 1.0" },
      { :fs, github: "VerKnowSys/fs" },
      { :exsync, github: "VerKnowSys/exsync", only: :dev },
      { :exlager, github: "khia/exlager" },
      { :amnesia, github: "meh/amnesia" },
      { :timex, "~> 0.18.2" },
      { :cowboy, "~> 1.0.0" },
      { :httpotion, github: "myfreeweb/httpotion" },
      { :credo, "~> 0.1.0", only: :dev }
    ]
  end
end
