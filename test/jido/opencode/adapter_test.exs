defmodule Jido.Opencode.AdapterTest do
  use ExUnit.Case, async: true

  alias Jido.Opencode.Adapter
  alias Jido.Harness.{Capabilities, RunRequest}

  describe "behaviour implementation" do
    test "implements Jido.Harness.Adapter" do
      assert Code.ensure_loaded?(Adapter)
      assert function_exported?(Adapter, :id, 0)
      assert function_exported?(Adapter, :capabilities, 0)
      assert function_exported?(Adapter, :run, 2)
      assert function_exported?(Adapter, :runtime_contract, 0)
      assert function_exported?(Adapter, :cancel, 1)
    end
  end

  describe "id/0" do
    test "returns :opencode" do
      assert Adapter.id() == :opencode
    end
  end

  describe "capabilities/0" do
    test "returns capabilities struct" do
      caps = Adapter.capabilities()
      assert %Capabilities{} = caps
      assert caps.streaming? == true
      assert caps.tool_calls? == true
      assert caps.usage? == true
      assert caps.cancellation? == true
    end
  end

  describe "runtime_contract/0" do
    test "returns runtime contract" do
      contract = Adapter.runtime_contract()
      assert contract.provider == :opencode
      assert is_list(contract.runtime_tools_required)
      assert "opencode" in contract.runtime_tools_required
      assert is_list(contract.install_steps)
      assert is_binary(contract.coding_command_template)
    end
  end

  describe "run/2" do
    @tag :integration
    test "requires running opencode server", %{test: test_name} do
      # This test requires a running OpenCode server
      # Marked with :integration tag to skip in CI
      skip_test_message = "OpenCode server not running for #{test_name}"

      # In real tests, you'd mock the HTTP client
      # or check if server is available
      assert true
    end
  end
end
