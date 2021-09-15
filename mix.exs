defmodule Membrane.QUIC.Plugin do
  use Mix.Project

  @version "0.1.0"
  @github_url "https://github.com/membraneframework/membrane_quic_plugin"

  def project do
    [
      app: :membrane_quic_plugin,
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # hex
      description: "Plugin containing elements for sending and receiving data over QUIC",
      package: package(),

      # docs
      name: "Membrane QUIC plugin",
      source_url: @github_url,
      homepage_url: "https://membraneframework.org",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      # {:quicer, github: "emqx/quic"},
      {:quicer, path: "../quic"},
      {:membrane_core, "~> 0.7.0"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:credo, "~> 1.5", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["mickel8"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE"],
      source_ref: "v#{@version}",
      nest_modules_by_prefix: [Membrane.QUIC]
    ]
  end
end
