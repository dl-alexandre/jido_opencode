defmodule Jido.Opencode.Error do
  @moduledoc """
  Error types for Jido.Opencode.

  Provides structured error handling with specific error types for different failure modes.
  """

  defmodule ValidationError do
    @moduledoc "Error raised when request validation fails."
    defexception [:message, :field, :details]

    @impl true
    def exception(opts) do
      field = Keyword.get(opts, :field)
      details = Keyword.get(opts, :details, %{})
      message = Keyword.get(opts, :message, "Validation failed for field: #{field}")

      %__MODULE__{
        message: message,
        field: field,
        details: details
      }
    end
  end

  defmodule ExecutionError do
    @moduledoc "Error raised when OpenCode execution fails."
    defexception [:message, :reason, :details]

    @impl true
    def exception(opts) do
      reason = Keyword.get(opts, :reason, :unknown)
      details = Keyword.get(opts, :details, %{})
      message = Keyword.get(opts, :message, "Execution failed: #{inspect(reason)}")

      %__MODULE__{
        message: message,
        reason: reason,
        details: details
      }
    end
  end

  defmodule CompatibilityError do
    @moduledoc "Error raised when OpenCode CLI is incompatible or not installed."
    defexception [:message, :reason, :current_version, :required_version]

    @impl true
    def exception(opts) do
      reason = Keyword.get(opts, :reason)
      current_version = Keyword.get(opts, :current_version)
      required_version = Keyword.get(opts, :required_version, ">= 1.0.0")

      message =
        case reason do
          :not_installed ->
            "OpenCode CLI not installed. Run: npm install -g opencode-ai"

          :version_too_old ->
            "OpenCode CLI version #{current_version} is too old. Required: #{required_version}"

          :server_not_running ->
            "OpenCode server not running. Start with: opencode"

          _ ->
            "OpenCode compatibility check failed: #{inspect(reason)}"
        end

      %__MODULE__{
        message: message,
        reason: reason,
        current_version: current_version,
        required_version: required_version
      }
    end
  end

  defmodule ServerError do
    @moduledoc "Error raised when OpenCode server returns an error."
    defexception [:message, :status_code, :response_body]

    @impl true
    def exception(opts) do
      status_code = Keyword.get(opts, :status_code)
      response_body = Keyword.get(opts, :response_body, "")

      message =
        Keyword.get(
          opts,
          :message,
          "OpenCode server error (HTTP #{status_code}): #{inspect(response_body)}"
        )

      %__MODULE__{
        message: message,
        status_code: status_code,
        response_body: response_body
      }
    end
  end

  @doc """
  Creates a validation error with the given message and field.
  """
  @spec validation_error(String.t(), keyword()) :: ValidationError.t()
  def validation_error(message, opts \\ []) do
    ValidationError.exception(Keyword.merge([message: message], opts))
  end

  @doc """
  Creates an execution error with the given reason and details.
  """
  @spec execution_error(atom(), map()) :: ExecutionError.t()
  def execution_error(reason, details \\ %{}) do
    ExecutionError.exception(reason: reason, details: details)
  end

  @doc """
  Creates a compatibility error for the given reason.
  """
  @spec compatibility_error(atom(), keyword()) :: CompatibilityError.t()
  def compatibility_error(reason, opts \\ []) do
    CompatibilityError.exception(Keyword.merge([reason: reason], opts))
  end

  @doc """
  Creates a server error for the given HTTP status and response.
  """
  @spec server_error(integer(), String.t()) :: ServerError.t()
  def server_error(status_code, response_body) do
    ServerError.exception(status_code: status_code, response_body: response_body)
  end
end
