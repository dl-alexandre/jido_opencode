defmodule Mix.Tasks.Opencode.Install do
  @moduledoc """
  Checks if OpenCode CLI is installed and provides installation instructions.

  ## Usage

      mix opencode.install

  ## Examples

      # Check installation
      mix opencode.install

      # Force show instructions even if installed
      mix opencode.install --instructions

  """

  use Mix.Task

  alias Jido.Opencode.Compatibility

  @shortdoc "Check/install OpenCode CLI"

  @impl true
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [instructions: :boolean])

    Mix.shell().info("Checking OpenCode CLI installation...")

    if Compatibility.cli_installed?() and not opts[:instructions] do
      version = Compatibility.installed_version()
      Mix.shell().info("✓ OpenCode CLI is installed (version #{version})")
      Mix.shell().info("\nNext steps:")
      Mix.shell().info("  1. Start OpenCode: opencode")
      Mix.shell().info("  2. Run /connect to configure your API key")
      Mix.shell().info("  3. Test with: mix opencode.smoke")
    else
      Mix.shell().error("✗ OpenCode CLI not found")
      Mix.shell().info("\nInstallation Instructions:\n")
      Mix.shell().info(Compatibility.installation_instructions())
    end
  end
end
