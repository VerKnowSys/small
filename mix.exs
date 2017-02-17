defmodule Small.Mixfile do
  use Mix.Project

  def project do
    [
      app: :small,
      version: "0.12.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      escript: escript(),
      dialyzer: [
        paths: [
          "_build/dev/lib/small/ebin",
        ],
      ]
    ]
  end


  def application do
    [extra_applications: [:logger, :uuid, :fs, :amnesia, :cowboy]]
  end


  defp mixenv do
    Atom.to_string Mix.env
  end


  def escript do
    [
      main_module: SmallApplication,
      embed_elixir: true,
      language: :elixir,
      force: true,
      emu_args: "-smp enable -sname small#{mixenv()}",
      comment: "ServeD",
    ]
  end


  # def applications do
  #   dev = [:exsync, :credo]
  #   prod = [:logger, :exlager, :ex_doc, :tzdata, :httpotion, :cowboy, :timex, :amnesia, :uuid, :fs]
  #   case Mix.env do
  #     :prod ->
  #       prod
  #     _ ->
  #       dev ++ prod
  #   end
  # end


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
      # { :exlager, github: "VerKnowSys/exlager" },
      # { :httpotion, github: "myfreeweb/httpotion" },
      # { :exsync, github: "VerKnowSys/exsync", only: :dev },
      # { :tzdata, "~> 0.5" }, # , override: :true
      # { :timex, "~> 1.0" },

      { :fs, github: "VerKnowSys/fs", branch: "master", override: true },
      { :amnesia, github: "meh/amnesia", branch: "master" },

      { :uuid, "~> 1.1" },
      { :cowboy, "~> 1.0" },
      { :credo, "~> 0.6", only: :dev },
      { :ex_doc, "~> 0.14", only: :prod },
    ]
  end
end
