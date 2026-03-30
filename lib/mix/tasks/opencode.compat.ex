defmodule Mix.Tasks.Opencode.Compat do
  @moduledoc """
  Runs compatibility checks for OpenCode CLI and server.

  ## Usage

      mix opencode.compat

  ## Examples

      # Run all compatibility checks
      mix opencode.compat

      # Verbose output
      mix opencode.compat --verbose

  """

  use Mix.Task

  alias Jido.Opencode.Compatibility

  @shortdoc "Check OpenCode compatibility"

  @impl true
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [verbose: :boolean])
    verbose = opts[:verbose] || false

    Mix.shell().info("Running OpenCode compatibility checks...\n")

    checks = [
      {"CLI Installed", &Compatibility.cli_installed?/0},
      {"Version Compatible", &Compatibility.compatible?/0},
      {"Server Running", &Compatibility.server_running?/0}
    ]

    results =
      Enum.map(checks, fn {name, check_fn} ->
        if verbose, do: Mix.shell().info("Checking: #{name}...")

        case check_fn.() do
          true ->
            if verbose, do: Mix.shell().info("  ✓ #{name}")
            {name, :ok}

          false ->
            Mix.shell().error("  ✗ #{name}")
            {name, :failed}
        end
      end)

    all_passed = Enum.all?(results, fn {_, status} -> status == :ok end)

    Mix.shell().info("")

    if all_passed do
      Mix.shell().info("✓ All compatibility checks passed!")
      version = Compatibility.installed_version()
      Mix.shell().info("  OpenCode version: #{version}")
    else
      Mix.shell().error("✗ Some compatibility checks failed")

      failed = Enum.filter(results, fn {_, status} -> status == :failed end)

      Mix.shell().info("\nFailed checks:")

      Enum.each(failed, fn {name, _} ->
        Mix.shell().error("  - #{name}")
      end)

      Mix.shell().info("\nTo fix:")

      if not Compatibility.cli_installed?() do
        Mix.shell().info(Compatibility.installation_instructions())
      end

      if not Compatibility.server_running?() do
        Mix.shell().info("\nStart the OpenCode server:")
        Mix.shell().info("  opencode")
      end

      System.halt(1)
    end
  end
end
