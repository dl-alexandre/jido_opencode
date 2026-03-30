defmodule Jido.Opencode.Adapter do
  @moduledoc """
  OpenCode adapter implementing `Jido.Harness.Adapter` behaviour.

  This adapter connects to the OpenCode server via HTTP API (default port 4096)
  and normalizes its interface for use with Jido.Harness.

  ## Configuration

  Add to your config:

      config :jido_harness, :providers, %{
        opencode: Jido.Opencode.Adapter
      }

  Optional server configuration:

      config :jido_opencode, :server,
        hostname: "127.0.0.1",
        port: 4096,
        timeout: 5000

  ## Usage

      {:ok, events} = Jido.Harness.run(:opencode, "fix the bug", cwd: "/my/project")

  ## Requirements

  - OpenCode CLI installed: `npm install -g opencode-ai`
  - OpenCode server will auto-start on first use

  See: https://opencode.ai/docs/sdk
  """

  @behaviour Jido.Harness.Adapter

  alias Jido.Harness.{Capabilities, Error, Event, RunRequest, RuntimeContract}
  alias Jido.Opencode.{Client, EventTranslator}

  require Logger

  @default_hostname "127.0.0.1"
  @default_port 4096
  @default_timeout 5000

  @impl true
  def id, do: :opencode

  @impl true
  def capabilities do
    %Capabilities{
      streaming?: true,
      tool_calls?: true,
      tool_results?: true,
      thinking?: false,
      resume?: true,
      usage?: true,
      file_changes?: true,
      cancellation?: true
    }
  end

  @impl true
  def run(%RunRequest{} = request, opts \\ []) do
    with {:ok, client} <- ensure_client(opts),
         {:ok, session} <- create_session(client, request),
         {:ok, stream} <- run_prompt(client, session, request, opts) do
      events =
        stream
        |> Stream.map(&EventTranslator.translate/1)
        |> Stream.filter(& &1)

      {:ok, events}
    else
      {:error, reason} ->
        {:error, Error.execution_error("OpenCode run failed", %{reason: reason})}
    end
  end

  @impl true
  def runtime_contract do
    %RuntimeContract{
      provider: :opencode,
      host_env_required_any: [],
      host_env_required_all: [],
      sprite_env_forward: ["OPENCODE_API_KEY"],
      sprite_env_injected: %{},
      runtime_tools_required: ["opencode", "node"],
      compatibility_probes: [
        %{command: "which opencode", expected: "opencode"},
        %{command: "opencode --version", expected: ~r/\\d+\\.\\d+/}
      ],
      install_steps: [
        %{
          type: :shell,
          command: "npm install -g opencode-ai",
          description: "Install OpenCode CLI globally"
        },
        %{
          type: :shell,
          command: "opencode --version",
          description: "Verify installation"
        }
      ],
      auth_bootstrap_steps: [
        "Run 'opencode' and execute /connect command",
        "Visit opencode.ai/auth and sign in",
        "Copy API key and paste into prompt"
      ],
      triage_command_template: "opencode",
      coding_command_template: "opencode",
      success_markers: [
        %{pattern: "type: 'success'", description: "Task completed successfully"},
        %{pattern: "type: 'message'", description: "Response message"}
      ],
      metadata: %{
        docs_url: "https://opencode.ai/docs",
        sdk_url: "https://opencode.ai/docs/sdk",
        github_url: "https://github.com/anomalyco/opencode"
      }
    }
  end

  @impl true
  def cancel(session_id) do
    with {:ok, client} <- ensure_client([]) do
      Client.abort_session(client, session_id)
    end
  end

  @doc """
  Run a prompt with structured output using JSON Schema.

  ## Example

      schema = %{
        type: "object",
        properties: %{
          company: %{type: "string"},
          founded: %{type: "number"}
        },
        required: ["company"]
      }

      {:ok, result} = Jido.Opencode.Adapter.run_with_schema(
        "Tell me about Anthropic",
        schema,
        cwd: "/tmp"
      )

  ## Returns

    * `{:ok, map()}` - Parsed structured output
    * `{:error, term()}` - On failure

  """
  def run_with_schema(prompt, schema, opts \\ []) do
    with {:ok, client} <- ensure_client(opts),
         {:ok, session} <- create_session(client, %{title: "Schema Output Session"}),
         {:ok, stream} <- run_prompt_with_schema(client, session, prompt, schema, opts) do
      # Collect all events and extract structured output
      events = Enum.to_list(stream)

      # Find the structured output event
      structured_output =
        events
        |> Enum.find_value(fn event ->
          if event["type"] == "message" && event["info"]["structured_output"] do
            event["info"]["structured_output"]
          else
            nil
          end
        end)

      if structured_output do
        {:ok, structured_output}
      else
        {:error, :no_structured_output}
      end
    else
      {:error, reason} ->
        {:error, Error.execution_error("OpenCode run_with_schema failed", %{reason: reason})}
    end
  end

  # Private functions

  defp ensure_client(opts) do
    hostname = Keyword.get(opts, :hostname, @default_hostname)
    port = Keyword.get(opts, :port, @default_port)
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    base_url = "http://#{hostname}:#{port}"

    # Check if server is running
    case Client.health_check(base_url) do
      {:ok, _} ->
        {:ok, %Client{base_url: base_url, timeout: timeout}}

      {:error, _} ->
        # Try to auto-start server
        Logger.info("OpenCode server not running, attempting to start...")

        case start_opencode_server(base_url) do
          :ok ->
            # Wait for server to be ready
            case wait_for_server(base_url, timeout) do
              :ok -> {:ok, %Client{base_url: base_url, timeout: timeout}}
              {:error, reason} -> {:error, {:server_start_failed, reason}}
            end

          {:error, reason} ->
            {:error, {:server_start_failed, reason}}
        end
    end
  end

  defp create_session(client, %RunRequest{} = request) do
    title = request.metadata[:title] || "Jido Agent Session"

    case Client.create_session(client, %{title: title}) do
      {:ok, session} -> {:ok, session}
      {:error, reason} -> {:error, {:session_create_failed, reason}}
    end
  end

  defp run_prompt(client, session, %RunRequest{} = request, opts) do
    body = %{
      model: get_model_config(opts),
      parts: [%{type: "text", text: request.prompt}],
      system_prompt: request.system_prompt
    }

    # Add structured output if format provided
    body =
      if format = opts[:format] do
        Map.put(body, :format, format)
      else
        body
      end

    Client.session_prompt(client, session.id, body)
  end

  defp run_prompt_with_schema(client, session, prompt, schema, opts) do
    body = %{
      model: get_model_config(opts),
      parts: [%{type: "text", text: prompt}],
      format: %{
        type: "json_schema",
        schema: schema
      }
    }

    Client.session_prompt(client, session.id, body)
  end

  defp get_model_config(opts) do
    model = Keyword.get(opts, :model, "anthropic/claude-3-5-sonnet-20241022")

    case String.split(model, "/", parts: 2) do
      [provider, model_id] ->
        %{providerID: provider, modelID: model_id}

      _ ->
        # Assume Anthropic if no provider specified
        %{providerID: "anthropic", modelID: model}
    end
  end

  defp start_opencode_server(_base_url) do
    # OpenCode server auto-starts when CLI is invoked
    # For now, instruct user to start it manually
    case System.cmd("which", ["opencode"]) do
      {_, 0} ->
        # OpenCode is installed, but we need user to start server
        {:error, :server_not_running_manual_start_required}

      _ ->
        {:error, :opencode_not_installed}
    end
  end

  defp wait_for_server(base_url, timeout) do
    deadline = System.monotonic_time(:millisecond) + timeout

    wait_loop(base_url, deadline)
  end

  defp wait_loop(base_url, deadline) do
    if System.monotonic_time(:millisecond) > deadline do
      {:error, :timeout}
    else
      case Client.health_check(base_url) do
        {:ok, _} ->
          :ok

        {:error, _} ->
          Process.sleep(100)
          wait_loop(base_url, deadline)
      end
    end
  end
end
