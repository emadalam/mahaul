defmodule Mahaul.MixProject do
  use Mix.Project

  @source_url "https://github.com/emadalam/mahaul"
  @version "0.4.1"

  def project do
    [
      app: :mahaul,
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      test_coverage: test_coverage(),
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],

      # Hex
      description: description(),
      package: package(),

      # Docs
      name: "Mahaul",
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs(),
      preferred_cli_env: [
        docs: :docs,
        "hex.publish": :docs,
        "lint.code": :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:git_hooks, "~> 0.7", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :docs, runtime: false},
      {:excoveralls, "~> 0.15.3", only: :test}
    ]
  end

  defp aliases do
    [
      setup: [
        "deps.get",
        "deps.compile",
        "git_hooks.install"
      ],
      "lint.code": [
        "format --check-formatted",
        "credo --strict"
      ]
    ]
  end

  defp test_coverage do
    [
      tool: ExCoveralls,
      export: "cov"
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "Mahaul",
      canonical: "http://hexdocs.pm/mahaul",
      source_url: @source_url,
      extras: [],
      groups_for_modules: [],
      formatters: ["html"]
    ]
  end

  defp description do
    """
    Parse and validate your environment variables easily in Elixir. Supports compile
    time validation and runtime parsing of all environment variable accessed from code.
    Validate all set environment variables against app requirements with defaults and
    fallbacks before booting the app.
    """
  end

  defp package do
    [
      maintainers: ["Emad Alam"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end
end
