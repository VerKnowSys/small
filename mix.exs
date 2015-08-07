defmodule Small.Mixfile do
  use Mix.Project

  def project do
    [
      app: :small,
      version: "0.3.1",
      elixir: "~> 1.0",
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
      applications: [:logger, :uuid, :fs],
      # mod: {SyncSupervisor, []}
    ]
  end

  def escript do
    [
      main_module: SmallApplication,
      embed_elixir: true,
      language: [:elixir, :erlang],
      force: true
    ]
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
      # { :exfswatch, git: "https://github.com/falood/exfswatch.git", tag: "v0.1.0" },
      { :uuid, "~> 1.0" },
      { :fs, github: "VerKnowSys/fs"}
      # { :fs, "~> 0.9" }
    ]
  end
end
