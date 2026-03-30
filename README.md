# jido_opencode

OpenCode adapter for Jido.Harness - Elixir integration with the popular open source AI coding agent (132K GitHub stars).

[![Hex.pm](https://img.shields.io/hexpm/v/jido_opencode.svg)](https://hex.pm/packages/jido_opencode)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/jido_opencode)

## Installation

Add `jido_opencode` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jido_opencode, "~> 0.1.0"}
  ]
end
```

## Requirements

1. **Install OpenCode CLI:**
   ```bash
   npm install -g opencode-ai
   # or
   curl -fsSL https://opencode.ai/install | bash
   ```

2. **Configure API Key:**
   Run `/connect` in OpenCode TUI or set via config (see below)

## Configuration

Configure the adapter in your application:

```elixir
# config/config.exs
config :jido_harness, :providers, %{
  opencode: Jido.Opencode.Adapter
}

# Optional: set as default
config :jido_harness, :default_provider, :opencode

# Optional: OpenCode server settings
config :jido_opencode, :server,
  hostname: "127.0.0.1",
  port: 4096,
  timeout: 5000
```

## Usage

### Basic Usage

```elixir
# Run with default provider
{:ok, events} = Jido.Harness.run("fix the bug", cwd: "/my/project")

# Run with explicit provider
{:ok, events} = Jido.Harness.run(:opencode, "refactor this function", cwd: "/my/project")

# With options
{:ok, events} = Jido.Harness.run(:opencode, "add tests", 
  cwd: "/my/project",
  model: "anthropic/claude-3-5-sonnet-20241022",
  max_turns: 10
)
```

### Session-Based Execution

```elixir
alias Jido.Harness.RunRequest

# Create a request
{:ok, request} = RunRequest.new(%{
  prompt: "Implement user authentication",
  cwd: "/my/app",
  system_prompt: "You are a security-focused developer..."
})

# Run it
{:ok, events} = Jido.Harness.run_request(:opencode, request)

# Process events
Enum.each(events, fn event ->
  case event.type do
    :message -> IO.puts("AI: #{event.content}")
    :tool_call -> IO.puts("Tool: #{event.content}")
    :usage -> IO.puts("Tokens: #{event.metadata.usage.total}")
    _ -> :ok
  end
end)
```

### Structured Output

```elixir
schema = %{
  type: "object",
  properties: %{
    company: %{type: "string"},
    founded: %{type: "number"},
    products: %{type: "array", items: %{type: "string"}}
  },
  required: ["company", "founded"]
}

{:ok, result} = Jido.Opencode.Adapter.run_with_schema(
  "Tell me about Anthropic",
  schema,
  cwd: "/tmp"
)

# result.data.info.structured_output
# => %{"company" => "Anthropic", "founded" => 2021, "products" => ["Claude", ...]}
```

## Features

- ✅ **Session Management** - Create, manage, and persist sessions
- ✅ **Streaming Events** - Real-time SSE event streaming
- ✅ **Structured Output** - JSON Schema validation
- ✅ **Multi-Model Support** - Claude, OpenAI, Gemini, local models
- ✅ **File Operations** - Search, read, modify files
- ✅ **Usage Tracking** - Token counting and cost tracking
- ✅ **Cancellation** - Graceful session abort
- ✅ **Type-Safe** - Full TypeScript-inspired Elixir types

## How It Works

```
Your Elixir App
      ↓
Jido.Harness
      ↓
jido_opencode.Adapter
      ↓ (HTTP)
OpenCode Server (localhost:4096)
      ↓
OpenCode SDK (@opencode-ai/sdk)
      ↓
Actual AI Agent Execution
```

## Documentation

- [Full Documentation](https://hexdocs.pm/jido_opencode)
- [OpenCode Docs](https://opencode.ai/docs)
- [OpenCode SDK Reference](https://opencode.ai/docs/sdk)
- [Jido.Harness](https://hexdocs.pm/jido_harness)

## Contributing

1. Fork it!
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Apache-2.0 - see LICENSE file
