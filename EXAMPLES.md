# Quick Start Example

This example shows how to use `jido_opencode` with `Jido.Harness`.

## Prerequisites

1. Install OpenCode CLI:
```bash
npm install -g opencode-ai
```

2. Configure OpenCode:
```bash
opencode
# Then run /connect to set up your API key
```

## Basic Usage

### 1. Configure the Adapter

Add to your `config/config.exs`:

```elixir
config :jido_harness, :providers, %{
  opencode: Jido.Opencode.Adapter
}

# Optional: set as default
config :jido_harness, :default_provider, :opencode
```

### 2. Run a Simple Prompt

```elixir
# Run with explicit provider
{:ok, events} = Jido.Harness.run(:opencode, "fix the bug", cwd: "/my/project")

# Or with default provider (if configured)
{:ok, events} = Jido.Harness.run("fix the bug", cwd: "/my/project")

# Process events
Enum.each(events, fn event ->
  case event.type do
    :message -> IO.puts("AI: #{event.content}")
    :tool_call -> IO.puts("Tool: #{event.content}")
    :usage -> IO.puts("Tokens: #{event.metadata.usage.total_tokens}")
    _ -> :ok
  end
end)
```

### 3. Use Structured Output (JSON Schema)

```elixir
schema = %{
  type: "object",
  properties: %{
    company: %{type: "string", description: "Company name"},
    founded: %{type: "number", description: "Year founded"},
    products: %{
      type: "array",
      items: %{type: "string"},
      description: "Main products"
    }
  },
  required: ["company", "founded"]
}

{:ok, result} = Jido.Opencode.Adapter.run_with_schema(
  "Tell me about Anthropic",
  schema,
  cwd: "/tmp"
)

# result will be:
# %{
#   "company" => "Anthropic",
#   "founded" => 2021,
#   "products" => ["Claude", "Claude API", "Claude Code"]
# }
```

### 4. Session-Based Execution

```elixir
alias Jido.Harness.RunRequest

# Create a request with metadata
{:ok, request} = RunRequest.new(%{
  prompt: "Implement user authentication",
  cwd: "/my/app",
  system_prompt: "You are a security-focused developer...",
  metadata: %{title: "Auth Implementation"}
})

# Run it
{:ok, events} = Jido.Harness.run_request(:opencode, request)

# Collect results
results = Enum.to_list(events)
```

### 5. Cancel a Running Session

```elixir
# Start a long-running task
{:ok, session_id} = # ... get from session

# Cancel it
:ok = Jido.Harness.cancel(:opencode, session_id)
```

## Advanced: Using the Client Directly

```elixir
alias Jido.Opencode.Client

# Create a client
{:ok, client} = Client.new()

# Create a session
{:ok, session} = Client.create_session(client, %{title: "My Task"})

# Send a prompt
{:ok, stream} = Client.session_prompt(client, session.id, %{
  parts: [%{type: "text", text: "Hello, analyze this code"}],
  model: %{providerID: "anthropic", modelID: "claude-3-5-sonnet-20241022"}
})

# Process the stream
Enum.each(stream, fn event ->
  IO.inspect(event)
end)

# Search for text in files
{:ok, matches} = Client.find_text(client, "function.*auth")
IO.inspect(matches)

# Read a file
{:ok, content} = Client.read_file(client, "src/auth.ts")
IO.inspect(content)
```

## Error Handling

```elixir
case Jido.Harness.run(:opencode, "task", cwd: "/project") do
  {:ok, events} ->
    # Process successful events
    :ok

  {:error, %Jido.Harness.Error{} = error} ->
    IO.puts("Error: #{error.message}")
    IO.inspect(error.metadata)
end
```

## Configuration Options

```elixir
config :jido_opencode, :server,
  hostname: "127.0.0.1",  # OpenCode server host
  port: 4096,              # OpenCode server port
  timeout: 5000           # Connection timeout (ms)

config :jido_opencode, :default_model,
  "anthropic/claude-3-5-sonnet-20241022"
```

## Notes

- OpenCode server must be running (starts automatically on first use)
- API key must be configured via `/connect` in OpenCode TUI
- Sessions persist until deleted or timeout
- Usage tracking includes token counts and estimated costs
