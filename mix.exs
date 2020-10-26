defmodule ExEventsProtocol.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_events_protocol,
      version: "0.1.0",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_core_path: "_build/#{Mix.env()}"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.3"},
      {:uuid, "~> 1.1"},
      {:xema, "~> 0.13"},
      {:jason, "~> 1.2"},
      {:plug, "~> 1.10"},
      {:mox, "~> 1.0", only: [:test]},
      {:stream_data, "~> 0.1", only: [:test, :dev]},
      {:credo, "1.5.0-rc.4", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
