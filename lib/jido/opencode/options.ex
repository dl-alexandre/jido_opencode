defmodule Jido.Opencode.Options do
  @moduledoc """
  Options normalization and validation for OpenCode runs.

  Transforms `Jido.Harness.RunRequest` and keyword options into a normalized
  options struct for OpenCode execution.
  """

  alias Jido.Harness.RunRequest
  alias Jido.Opencode.Error.ValidationError

  defstruct [
    :prompt,
    :cwd,
    :model,
    :max_turns,
    :timeout_ms,
    :system_prompt,
    :allowed_tools,
    :attachments,
    :output_format,
    :metadata,
    :env
  ]

  @type t :: %__MODULE__{
          prompt: String.t(),
          cwd: String.t() | nil,
          model: String.t() | nil,
          max_turns: pos_integer() | nil,
          timeout_ms: pos_integer() | nil,
          system_prompt: String.t() | nil,
          allowed_tools: list(String.t()) | nil,
          attachments: list(map()) | nil,
          output_format: map() | nil,
          metadata: map(),
          env: map()
        }

  @default_model "anthropic/claude-3-5-sonnet-20241022"
  @default_max_turns 50
  # 5 minutes
  @default_timeout_ms 300_000

  @doc """
  Creates options from a RunRequest and keyword options.

  ## Examples

      iex> request = %Jido.Harness.RunRequest{prompt: "Hello", cwd: "/tmp"}
      iex> Jido.Opencode.Options.from_run_request(request, [model: "gpt-4"])
      {:ok, %Jido.Opencode.Options{prompt: "Hello", cwd: "/tmp", model: "gpt-4"}}

  """
  @spec from_run_request(RunRequest.t(), keyword()) :: {:ok, t()} | {:error, ValidationError.t()}
  def from_run_request(%RunRequest{} = request, opts \\ []) do
    options = %__MODULE__{
      prompt: request.prompt,
      cwd: request.cwd || opts[:cwd],
      model: opts[:model] || @default_model,
      max_turns: opts[:max_turns] || @default_max_turns,
      timeout_ms: opts[:timeout_ms] || @default_timeout_ms,
      system_prompt: request.system_prompt || opts[:system_prompt],
      allowed_tools: opts[:allowed_tools],
      attachments: request.attachments || opts[:attachments],
      output_format: opts[:format] || opts[:output_format],
      metadata: Map.merge(request.metadata || %{}, Map.new(opts[:metadata] || [])),
      env: Map.new(opts[:env] || [])
    }

    case validate(options) do
      :ok -> {:ok, options}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Validates the options struct.
  """
  @spec validate(t()) :: :ok | {:error, ValidationError.t()}
  def validate(%__MODULE__{} = options) do
    cond do
      is_nil(options.prompt) or options.prompt == "" ->
        {:error, ValidationError.exception(field: :prompt, message: "Prompt is required")}

      not is_nil(options.cwd) and not File.dir?(options.cwd) ->
        {:error,
         ValidationError.exception(
           field: :cwd,
           message: "Working directory does not exist: #{options.cwd}"
         )}

      not is_nil(options.max_turns) and options.max_turns < 1 ->
        {:error,
         ValidationError.exception(
           field: :max_turns,
           message: "max_turns must be at least 1"
         )}

      not is_nil(options.timeout_ms) and options.timeout_ms < 1000 ->
        {:error,
         ValidationError.exception(
           field: :timeout_ms,
           message: "timeout_ms must be at least 1000ms"
         )}

      true ->
        :ok
    end
  end

  @doc """
  Converts options to the format expected by OpenCode API.
  """
  @spec to_api_body(t()) :: map()
  def to_api_body(%__MODULE__{} = options) do
    body = %{
      model: parse_model(options.model),
      parts: build_parts(options)
    }

    # Add optional fields
    body =
      if options.system_prompt do
        Map.put(body, :system_prompt, options.system_prompt)
      else
        body
      end

    body =
      if options.output_format do
        Map.put(body, :format, options.output_format)
      else
        body
      end

    body
  end

  @doc """
  Returns default options.
  """
  @spec defaults() :: t()
  def defaults do
    %__MODULE__{
      model: @default_model,
      max_turns: @default_max_turns,
      timeout_ms: @default_timeout_ms,
      metadata: %{},
      env: %{}
    }
  end

  # Private functions

  defp parse_model(nil), do: %{providerID: "anthropic", modelID: "claude-3-5-sonnet-20241022"}

  defp parse_model(model) when is_binary(model) do
    case String.split(model, "/", parts: 2) do
      [provider, model_id] ->
        %{providerID: provider, modelID: model_id}

      _ ->
        # Assume Anthropic if no provider specified
        %{providerID: "anthropic", modelID: model}
    end
  end

  defp build_parts(%__MODULE__{prompt: prompt, attachments: nil}) do
    [%{type: "text", text: prompt}]
  end

  defp build_parts(%__MODULE__{prompt: prompt, attachments: attachments}) do
    parts = [%{type: "text", text: prompt}]

    attachment_parts =
      Enum.map(attachments, fn
        %{type: "image", path: path} ->
          %{type: "image", source: %{type: "local", path: path}}

        %{type: "file", path: path} ->
          %{type: "file", source: %{type: "local", path: path}}

        other ->
          other
      end)

    parts ++ attachment_parts
  end
end
