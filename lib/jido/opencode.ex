defmodule Jido.Opencode do
  @moduledoc """
  OpenCode integration for Jido.Harness.

  This module provides the public API for interacting with OpenCode
  through the Jido.Harness protocol.

  ## Quick Start

      # Configure the adapter
      config :jido_harness, :providers, %{
        opencode: Jido.Opencode.Adapter
      }

      # Run a prompt
      {:ok, events} = Jido.Harness.run(:opencode, "fix the bug", cwd: "/my/project")

  ## Direct API Access

  You can also use the client directly:

      {:ok, client} = Jido.Opencode.Client.new()
      {:ok, session} = Jido.Opencode.Client.create_session(client, %{title: "My Task"})
      {:ok, events} = Jido.Opencode.Client.session_prompt(client, session.id, %{
        parts: [%{type: "text", text: "Hello"}]
      })

  See `Jido.Opencode.Adapter` for the full adapter implementation,
  and `Jido.Opencode.Client` for the HTTP client.
  """

  @doc """
  Returns the adapter module.
  """
  def adapter, do: Jido.Opencode.Adapter

  @doc """
  Returns the client module.
  """
  def client, do: Jido.Opencode.Client

  @doc """
  Helper to run OpenCode with structured output.
  """
  def run_with_schema(prompt, schema, opts \\ []) do
    Jido.Opencode.Adapter.run_with_schema(prompt, schema, opts)
  end
end
