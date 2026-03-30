defmodule Jido.Opencode.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/dl-alexandre/jido_opencode"

  def project do
    [
      app: :jido_opencode,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "Jido.Opencode",
      source_url: @source_url,
      docs: docs(),
      dialyzer: dialyzer()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Jido.Opencode.Application, []}
    ]
  end

  defp deps do
    [
      # Core dependencies
      {:jido_harness, "~> 0.1.0"},

      # HTTP client for OpenCode API
      {:req, "~> 0.5.0"},

      # JSON handling
      {:jason, "~> 1.4"},

      # Server-Sent Events (SSE) for streaming
      {:sse, "~> 0.2.0"},

      # Schema validation
      {:zoi, "~> 0.1.0"},

      # Development dependencies
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:mox, "~> 1.2", only: :test}
    ]
  end

  defp description do
    "OpenCode adapter for Jido.Harness - Elixir integration with the popular open source AI coding agent"
  end

  defp package do
    [
      name: :jido_opencode,
      files: ["lib", "mix.exs", "README.md", "LICENSE", "CHANGELOG.md"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "OpenCode" => "https://opencode.ai",
        "Docs" => "https://hexdocs.pm/jido_opencode"
      },
      maintainers: ["Your Name"]
    ]
  end

  defp docs do
    [
      main: "Jido.Opencode",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end

  defp dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_add_deps: :apps_direct
    ]
  end
end
