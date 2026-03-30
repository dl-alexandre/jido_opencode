defmodule Jido.Opencode.Application do
  @moduledoc false
  use Application

  alias Jido.Opencode.SessionRegistry

  @impl true
  def start(_type, _args) do
    children = [
      # Session registry for tracking active sessions (enables cancellation)
      SessionRegistry

      # Optional: Add a supervisor for connection pooling
      # {Jido.Opencode.ConnectionPool, []}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Jido.Opencode.Supervisor)
  end
end
