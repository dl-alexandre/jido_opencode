ExUnit.start()

# Configure test environment
config = %{
  hostname: "127.0.0.1",
  port: 4096,
  timeout: 5000
}

Application.put_env(:jido_opencode, :server, config)
