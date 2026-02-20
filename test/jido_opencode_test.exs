defmodule JidoOpenCodeTest do
  use ExUnit.Case
  doctest JidoOpenCode

  describe "query/1" do
    test "returns ok tuple with result" do
      assert {:ok, result} = JidoOpenCode.query("test query")
      assert is_map(result)
      assert result["query"] == "test query"
    end
  end

  describe "version/0" do
    test "returns version string" do
      version = JidoOpenCode.version()
      assert is_binary(version)
      assert version == "0.1.0"
    end
  end
end
