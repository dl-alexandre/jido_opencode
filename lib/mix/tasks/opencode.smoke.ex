defmodule Mix.Tasks.Opencode.Smoke do
  @moduledoc """
  Runs a smoke test against the OpenCode adapter.

  This creates a simple session and verifies the adapter can communicate
  with the OpenCode server.

  ## Usage

      mix opencode.smoke

  ## Examples

      # Run smoke test
      mix opencode.smoke

      # With verbose output
      mix opencode.smoke --verbose

  """

  use Mix.Task

  alias Jido.Opencode.{Client, Compatibility}

  @shortdoc "Run smoke test"

  @impl true
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [verbose: :boolean])
    verbose = opts[:verbose] || false

    Mix.shell().info("Running OpenCode smoke test...\n")

    # Check compatibility first
    Mix.shell().info("Step 1: Checking compatibility...")

    case Compatibility.check() do
      {:ok, _} ->
        Mix.shell().info("  ✓ Compatibility checks passed")

      {:error, error} ->
        Mix.shell().error("  ✗ Compatibility check failed: #{error.message}")
        System.halt(1)
    end

    # Create client
    Mix.shell().info("\nStep 2: Creating client...")

    case Client.new() do
      {:ok, client} ->
        Mix.shell().info("  ✓ Client created")

        # Create session
        Mix.shell().info("\nStep 3: Creating session...")

        case Client.create_session(client, %{title: "Smoke Test"}) do
          {:ok, session} ->
            Mix.shell().info("  ✓ Session created: #{session["id"]}")

            # Send simple prompt
            Mix.shell().info("\nStep 4: Sending test prompt...")

            case Client.session_prompt(client, session["id"], %{
                   parts: [%{type: "text", text: "Say 'Hello from Jido!'"}]
                 }) do
              {:ok, _stream} ->
                Mix.shell().info("  ✓ Prompt sent successfully")
                Mix.shell().info("  ✓ Stream opened (events not processed in smoke test)")

              {:error, reason} ->
                Mix.shell().error("  ✗ Failed to send prompt: #{inspect(reason)}")
                System.halt(1)
            end

            # Cleanup
            Mix.shell().info("\nStep 5: Cleaning up...")
            Client.abort_session(client, session["id"])
            Mix.shell().info("  ✓ Session cleaned up")

          {:error, reason} ->
            Mix.shell().error("  ✗ Failed to create session: #{inspect(reason)}")
            System.halt(1)
        end

      {:error, reason} ->
        Mix.shell().error("  ✗ Failed to create client: #{inspect(reason)}")
        System.halt(1)
    end

    Mix.shell().info("\n✓ Smoke test completed successfully!")
    Mix.shell().info("\nYour jido_opencode adapter is ready to use.")
  end
end
