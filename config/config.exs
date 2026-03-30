import Config

# Default OpenCode server configuration
config :jido_opencode, :server,
  hostname: "127.0.0.1",
  port: 4096,
  timeout: 5000

# Optional: Configure default model
config :jido_opencode, :default_model, "anthropic/claude-3-5-sonnet-20241022"

# Optional: Configure logging
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
