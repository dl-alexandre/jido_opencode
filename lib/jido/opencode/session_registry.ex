defmodule Jido.Opencode.SessionRegistry do
  @moduledoc """
  Registry for tracking active OpenCode sessions.

  Enables session lookup for cancellation and monitoring.
  Uses an ETS table for fast lookups and process monitoring
  to automatically clean up sessions when their owner processes die.
  """

  use GenServer

  require Logger

  @table_name :jido_opencode_sessions
  # Sessions expire after 30 minutes
  @default_ttl :timer.minutes(30)

  # Client API

  @doc """
  Starts the session registry.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Registers a new active session.

  ## Examples

      iex> Jido.Opencode.SessionRegistry.register("session-123", %{
      ...>   session_id: "session-123",
      ...>   pid: self(),
      ...>   client: client,
      ...>   started_at: DateTime.utc_now()
      ...> })
      :ok

  """
  @spec register(String.t(), map()) :: :ok
  def register(session_id, session_data) when is_binary(session_id) do
    GenServer.call(__MODULE__, {:register, session_id, session_data})
  end

  @doc """
  Fetches session data by session ID.

  ## Examples

      iex> Jido.Opencode.SessionRegistry.fetch("session-123")
      {:ok, %{session_id: "session-123", pid: #PID<0.123.0>, ...}}

      iex> Jido.Opencode.SessionRegistry.fetch("nonexistent")
      {:error, :not_found}

  """
  @spec fetch(String.t()) :: {:ok, map()} | {:error, :not_found}
  def fetch(session_id) when is_binary(session_id) do
    case :ets.lookup(@table_name, session_id) do
      [{^session_id, data}] -> {:ok, data}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Checks if a session exists.
  """
  @spec exists?(String.t()) :: boolean()
  def exists?(session_id) when is_binary(session_id) do
    match?([{_}], :ets.lookup(@table_name, session_id))
  end

  @doc """
  Deletes a session from the registry.

  ## Examples

      iex> Jido.Opencode.SessionRegistry.delete("session-123")
      :ok

  """
  @spec delete(String.t()) :: :ok
  def delete(session_id) when is_binary(session_id) do
    GenServer.call(__MODULE__, {:delete, session_id})
  end

  @doc """
  Lists all active session IDs.
  """
  @spec list() :: list(String.t())
  def list do
    :ets.select(@table_name, [{{:"$1", :_}, [], [:"$1"]}])
  end

  @doc """
  Gets the count of active sessions.
  """
  @spec count() :: non_neg_integer()
  def count do
    :ets.info(@table_name, :size)
  end

  @doc """
  Clears all sessions from the registry.
  """
  @spec clear() :: :ok
  def clear do
    GenServer.call(__MODULE__, :clear)
  end

  @doc """
  Checks if a session is still active (owner process is alive).
  """
  @spec active?(String.t()) :: boolean()
  def active?(session_id) when is_binary(session_id) do
    case fetch(session_id) do
      {:ok, %{pid: pid}} -> Process.alive?(pid)
      {:error, :not_found} -> false
    end
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    # Create ETS table
    table =
      :ets.new(@table_name, [
        :set,
        :protected,
        :named_table,
        read_concurrency: true
      ])

    # Schedule cleanup of expired sessions
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    schedule_cleanup(ttl)

    {:ok, %{table: table, ttl: ttl}}
  end

  @impl true
  def handle_call({:register, session_id, data}, _from, state) do
    # Store session with timestamp
    data_with_timestamp = Map.put(data, :registered_at, System.monotonic_time(:millisecond))

    # Monitor the owner process so we can clean up if it dies
    if pid = data[:pid] do
      Process.monitor(pid)
    end

    true = :ets.insert(@table_name, {session_id, data_with_timestamp})
    Logger.debug("Registered OpenCode session: #{session_id}")

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:delete, session_id}, _from, state) do
    :ets.delete(@table_name, session_id)
    Logger.debug("Deleted OpenCode session: #{session_id}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:clear, _from, state) do
    :ets.delete_all_objects(@table_name)
    Logger.info("Cleared all OpenCode sessions")
    {:reply, :ok, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    # Process died, find and remove its sessions
    sessions_to_delete =
      :ets.select(@table_name, [
        {{:"$1", %{pid: ^pid}}, [], [:"$1"]}
      ])

    Enum.each(sessions_to_delete, fn session_id ->
      :ets.delete(@table_name, session_id)
      Logger.debug("Cleaned up session #{session_id} (owner process died)")
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    # Clean up expired sessions
    now = System.monotonic_time(:millisecond)
    max_age_ms = state.ttl

    expired_sessions =
      :ets.select(@table_name, [
        {{:"$1", %{registered_at: :"$2"}},
         [{:>, {:+, {:const, now}, {:const, max_age_ms}}, :"$2"}], [:"$1"]}
      ])

    Enum.each(expired_sessions, fn session_id ->
      :ets.delete(@table_name, session_id)
      Logger.debug("Cleaned up expired session: #{session_id}")
    end)

    schedule_cleanup(state.ttl)
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Private functions

  defp schedule_cleanup(ttl) do
    Process.send_after(self(), :cleanup, ttl)
  end
end
