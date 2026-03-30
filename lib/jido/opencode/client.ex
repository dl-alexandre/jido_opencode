defmodule Jido.Opencode.Client do
  @moduledoc """
  HTTP client for OpenCode server API.

  Wraps the OpenCode HTTP API (default localhost:4096) using Req.

  See: https://opencode.ai/docs/sdk
  """

  alias Jido.Opencode.Client

  defstruct [:base_url, :timeout]

  @type t :: %__MODULE__{
          base_url: String.t(),
          timeout: non_neg_integer()
        }

  @doc """
  Performs a health check to verify the OpenCode server is running.
  """
  @spec health_check(String.t()) :: {:ok, map()} | {:error, term()}
  def health_check(base_url) do
    case Req.get("#{base_url}/health", receive_timeout: 2000) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Creates a new session.
  """
  @spec create_session(t(), map()) :: {:ok, map()} | {:error, term()}
  def create_session(%Client{base_url: base_url}, params) do
    url = "#{base_url}/api/session"

    case Req.post(url, json: params, receive_timeout: 5000) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Sends a prompt to a session and returns a stream of events.
  """
  @spec session_prompt(t(), String.t(), map()) :: {:ok, Enumerable.t()} | {:error, term()}
  def session_prompt(%Client{base_url: base_url}, session_id, body) do
    url = "#{base_url}/api/session/#{session_id}/prompt"

    # For streaming responses, we use Req with stream: true
    # or handle Server-Sent Events (SSE)
    case Req.post(url,
           json: body,
           receive_timeout: 60_000,
           into: :stream
         ) do
      {:ok, %{status: 200, body: stream}} ->
        {:ok, parse_sse_stream(stream)}

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Lists all sessions.
  """
  @spec list_sessions(t()) :: {:ok, list(map())} | {:error, term()}
  def list_sessions(%Client{base_url: base_url}) do
    url = "#{base_url}/api/session"

    case Req.get(url, receive_timeout: 5000) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Gets a specific session.
  """
  @spec get_session(t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get_session(%Client{base_url: base_url}, session_id) do
    url = "#{base_url}/api/session/#{session_id}"

    case Req.get(url, receive_timeout: 5000) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Aborts a running session.
  """
  @spec abort_session(t(), String.t()) :: :ok | {:error, term()}
  def abort_session(%Client{base_url: base_url}, session_id) do
    url = "#{base_url}/api/session/#{session_id}/abort"

    case Req.post(url, receive_timeout: 5000) do
      {:ok, %{status: 200}} ->
        :ok

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Searches for text in files.
  """
  @spec find_text(t(), String.t()) :: {:ok, list(map())} | {:error, term()}
  def find_text(%Client{base_url: base_url}, pattern) do
    url = "#{base_url}/api/find/text"

    case Req.get(url,
           params: [query: pattern],
           receive_timeout: 10_000
         ) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Reads a file.
  """
  @spec read_file(t(), String.t()) :: {:ok, map()} | {:error, term()}
  def read_file(%Client{base_url: base_url}, path) do
    url = "#{base_url}/api/file/read"

    case Req.get(url,
           params: [path: path],
           receive_timeout: 5000
         ) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private functions

  defp parse_sse_stream(stream) do
    # Parse Server-Sent Events stream
    # Each event is: "data: {...}\n\n"
    stream
    |> Stream.chunk_while(
      "",
      fn data, acc ->
        buffer = acc <> data

        case String.split(buffer, "\n\n", parts: 2) do
          [event, rest] ->
            {:cont, parse_event(event), rest}

          _ ->
            {:cont, buffer}
        end
      end,
      fn acc ->
        # Handle remaining buffer at end
        if acc != "" do
          {:cont, parse_event(acc), ""}
        else
          {:cont, "", ""}
        end
      end
    )
    |> Stream.filter(& &1)
  end

  defp parse_event(event_string) do
    event_string
    |> String.split("\n")
    |> Enum.reduce(%{}, fn line, acc ->
      case String.split(line, ":", parts: 2) do
        ["data", value] ->
          case Jason.decode(String.trim(value)) do
            {:ok, data} -> Map.merge(acc, data)
            {:error, _} -> acc
          end

        ["event", type] ->
          Map.put(acc, :event_type, String.trim(type))

        _ ->
          acc
      end
    end)
    |> case do
      map when map_size(map) > 0 -> map
      _ -> nil
    end
  end
end
