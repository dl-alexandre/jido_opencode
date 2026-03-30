defmodule Jido.Opencode.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Optional: Add a supervisor for connection pooling
      # {Jido.Opencode.ConnectionPool, []}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Jido.Opencode.Supervisor)
  end
end
