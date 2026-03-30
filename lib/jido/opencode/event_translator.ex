defmodule Jido.Opencode.EventTranslator do
  @moduledoc """
  Translates OpenCode server events to Jido.Harness.Event structs.

  OpenCode sends Server-Sent Events (SSE) with various types:
  - message - AI response messages
  - tool_call - Tool execution requests
  - tool_result - Tool execution results
  - usage - Token usage information
  - file_change - File modification events
  - error - Error events

  This module normalizes these into Jido.Harness.Event format.
  """

  alias Jido.Harness.Event

  require Logger

  @doc """
  Translates an OpenCode event map to a Jido.Harness.Event struct.

  Returns nil for events that should be filtered out.
  """
  @spec translate(map()) :: Event.t() | nil
  def translate(event) when is_map(event) do
    type = determine_event_type(event)
    content = extract_content(event)
    metadata = extract_metadata(event)

    if type && content do
      %Event{
        type: type,
        content: content,
        metadata: metadata,
        timestamp: DateTime.utc_now()
      }
    else
      nil
    end
  end

  def translate(_), do: nil

  # Private functions

  defp determine_event_type(event) do
    cond do
      # Tool calls
      event["tool_calls"] || event["type"] == "tool_call" ->
        :tool_call

      # Tool results
      event["tool_results"] || event["type"] == "tool_result" ->
        :tool_result

      # Usage/events
      event["usage"] || event["type"] == "usage" ->
        :usage

      # File changes
      event["file_changes"] || event["type"] == "file_change" ->
        :file_changes

      # Error events
      event["error"] || event["type"] == "error" ->
        :error

      # Regular messages
      event["type"] == "message" || event["content"] || event["text"] ->
        :message

      # Progress/status updates
      event["progress"] || event["status"] ->
        :status

      # Unknown type - log and skip
      true ->
        Logger.debug("Unknown OpenCode event type: #{inspect(event)}")
        nil
    end
  end

  defp extract_content(event) do
    cond do
      # Direct content
      is_binary(event["content"]) ->
        event["content"]

      # Text in parts
      parts = event["parts"] ->
        parts
        |> Enum.map(fn
          %{"type" => "text", "text" => text} -> text
          %{"content" => content} -> content
          _ -> ""
        end)
        |> Enum.join(" ")

      # Tool calls
      calls = event["tool_calls"] ->
        Jason.encode!(calls)

      # Tool results
      results = event["tool_results"] ->
        Jason.encode!(results)

      # Error message
      error = event["error"] ->
        if is_map(error), do: error["message"] || inspect(error), else: inspect(error)

      # File changes
      changes = event["file_changes"] ->
        Jason.encode!(changes)

      # Usage info
      usage = event["usage"] ->
        Jason.encode!(usage)

      # Fallback
      true ->
        Jason.encode!(event)
    end
  end

  defp extract_metadata(event) do
    metadata = %{}

    # Extract usage info if present
    metadata =
      if usage = event["usage"] do
        Map.put(metadata, :usage, normalize_usage(usage))
      else
        metadata
      end

    # Extract model info
    metadata =
      if model = event["model"] do
        Map.put(metadata, :model, model)
      else
        metadata
      end

    # Extract file changes
    metadata =
      if changes = event["file_changes"] do
        Map.put(metadata, :files_changed, changes)
      else
        metadata
      end

    # Extract tool info
    metadata =
      if tools = event["tool_calls"] || event["tool_results"] do
        Map.put(metadata, :tools, tools)
      else
        metadata
      end

    # Extract session info
    metadata =
      if session = event["session"] do
        Map.put(metadata, :session_id, session["id"])
      else
        metadata
      end

    metadata
  end

  defp normalize_usage(usage) when is_map(usage) do
    %{
      input_tokens: usage["input_tokens"] || usage["prompt_tokens"] || 0,
      output_tokens: usage["output_tokens"] || usage["completion_tokens"] || 0,
      total_tokens: usage["total_tokens"] || 0,
      cost_usd: usage["cost"] || usage["estimated_cost"] || nil
    }
  end

  defp normalize_usage(_), do: %{input_tokens: 0, output_tokens: 0, total_tokens: 0}
end
