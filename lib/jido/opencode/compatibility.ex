defmodule Jido.Opencode.Compatibility do
  @moduledoc """
  Compatibility checks for OpenCode CLI.

  Verifies that OpenCode is installed and meets minimum version requirements.
  """

  alias Jido.Opencode.Error.CompatibilityError

  @minimum_version "1.0.0"
  @default_server_url "http://127.0.0.1:4096"

  @doc """
  Returns true if the OpenCode CLI binary can be found.

  ## Examples

      iex> Jido.Opencode.Compatibility.cli_installed?()
      true

  """
  @spec cli_installed?() :: boolean()
  def cli_installed? do
    case System.cmd("which", ["opencode"], stderr_to_stdout: true) do
      {_, 0} -> true
      _ -> false
    end
  end

  @doc """
  Returns the installed OpenCode version, or nil if not installed.

  ## Examples

      iex> Jido.Opencode.Compatibility.installed_version()
      "1.3.6"

  """
  @spec installed_version() :: String.t() | nil
  def installed_version do
    case System.cmd("opencode", ["--version"], stderr_to_stdout: true) do
      {output, 0} ->
        output
        |> String.trim()
        |> extract_version()

      _ ->
        nil
    end
  end

  @doc """
  Checks if the installed OpenCode version meets minimum requirements.

  ## Examples

      iex> Jido.Opencode.Compatibility.compatible?()
      true

      iex> Jido.Opencode.Compatibility.compatible?(version: "1.3.6")
      true

  """
  @spec compatible?(keyword()) :: boolean()
  def compatible?(opts \\ []) do
    required_version = Keyword.get(opts, :version, @minimum_version)

    case installed_version() do
      nil ->
        false

      current_version ->
        version_satisfies?(current_version, required_version)
    end
  end

  @doc """
  Checks if the OpenCode server is running.

  ## Examples

      iex> Jido.Opencode.Compatibility.server_running?()
      true

      iex> Jido.Opencode.Compatibility.server_running?(url: "http://localhost:4096")
      true

  """
  @spec server_running?(keyword()) :: boolean()
  def server_running?(opts \\ []) do
    url = Keyword.get(opts, :url, @default_server_url)

    case Req.get("#{url}/health",
           receive_timeout: 2000,
           retry: false
         ) do
      {:ok, %{status: 200}} -> true
      _ -> false
    end
  end

  @doc """
  Performs full compatibility check and returns detailed status.

  ## Examples

      iex> Jido.Opencode.Compatibility.check()
      {:ok, %{cli_installed: true, version: "1.3.6", server_running: true}}

      iex> Jido.Opencode.Compatibility.check()
      {:error, %CompatibilityError{reason: :not_installed}}

  """
  @spec check(keyword()) :: {:ok, map()} | {:error, CompatibilityError.t()}
  def check(opts \\ []) do
    required_version = Keyword.get(opts, :version, @minimum_version)

    cond do
      not cli_installed?() ->
        {:error, CompatibilityError.exception(reason: :not_installed)}

      not version_satisfies?(installed_version(), required_version) ->
        {:error,
         CompatibilityError.exception(
           reason: :version_too_old,
           current_version: installed_version(),
           required_version: required_version
         )}

      not server_running?(opts) ->
        {:error, CompatibilityError.exception(reason: :server_not_running)}

      true ->
        {:ok,
         %{
           cli_installed: true,
           version: installed_version(),
           server_running: true,
           meets_requirements: true
         }}
    end
  end

  @doc """
  Asserts compatibility, raising an error if checks fail.

  ## Examples

      Jido.Opencode.Compatibility.assert!()
      # => :ok

      Jido.Opencode.Compatibility.assert!()
      # => raises CompatibilityError

  """
  @spec assert!(keyword()) :: :ok | no_return()
  def assert!(opts \\ []) do
    case check(opts) do
      {:ok, _} -> :ok
      {:error, error} -> raise error
    end
  end

  @doc """
  Returns installation instructions for OpenCode.
  """
  @spec installation_instructions() :: String.t()
  def installation_instructions do
    """
    OpenCode is not installed. To install:

    Using npm (recommended):
        npm install -g opencode-ai

    Using Homebrew (macOS/Linux):
        brew install anomalyco/tap/opencode

    Using the install script:
        curl -fsSL https://opencode.ai/install | bash

    After installation, configure your API key:
        opencode
        # Then run /connect and follow the prompts

    For more options, see: https://opencode.ai/docs
    """
  end

  # Private functions

  defp extract_version(output) do
    # Extract version from output like "opencode version 1.3.6" or just "1.3.6"
    case Regex.run(~r/(\d+\.\d+\.\d+(?:-[\w\.]+)?)/, output) do
      [version | _] -> version
      _ -> nil
    end
  end

  defp version_satisfies?(current_version, required_version) when is_binary(current_version) do
    # Simple version comparison - just check if current >= required
    current_parts = parse_version(current_version)
    required_parts = parse_version(required_version)

    compare_versions(current_parts, required_parts) >= 0
  end

  defp version_satisfies?(_, _), do: false

  defp parse_version(version_string) when is_binary(version_string) do
    version_string
    |> String.split(~r/[-+]/, parts: 2)
    |> List.first()
    |> String.split(".")
    |> Enum.map(fn part ->
      case Integer.parse(part) do
        {num, _} -> num
        :error -> 0
      end
    end)
    |> pad_to_three()
  end

  defp parse_version(_), do: [0, 0, 0]

  defp pad_to_three([major, minor, patch]), do: [major, minor, patch]
  defp pad_to_three([major, minor]), do: [major, minor, 0]
  defp pad_to_three([major]), do: [major, 0, 0]
  defp pad_to_three([]), do: [0, 0, 0]

  defp compare_versions([c_maj, c_min, c_pat], [r_maj, r_min, r_pat]) do
    cond do
      c_maj > r_maj -> 1
      c_maj < r_maj -> -1
      c_min > r_min -> 1
      c_min < r_min -> -1
      c_pat > r_pat -> 1
      c_pat < r_pat -> -1
      true -> 0
    end
  end
end
