defmodule ExSTUN.Message.TypeTest do
  use ExUnit.Case

  alias ExSTUN.Message.Type

  test "Type.to_value/1 converts type to integer correctly" do
    type = %Type{class: :request, method: :binding}
    assert 0x0001 = Type.to_value(type)

    type = %Type{class: :success_response, method: :binding}
    assert 0x0101 = Type.to_value(type)
  end

  test "Type.from_value/1 converts correct integer into t:Type.t/0" do
    assert {:ok, %Type{class: :request, method: :binding}} = Type.from_value(0x0001)
    assert {:ok, %Type{class: :success_response, method: :binding}} = Type.from_value(0x0101)
  end

  test "Type.from_value/1 returns error for incorrect integer" do
    import Bitwise

    # out of range
    assert {:error, :malformed_type} = Type.from_value(2 <<< 14)
    assert {:error, :malformed_type} = Type.from_value(2 <<< (14 + 1))

    # some random, unsupported value
    assert {:error, :unknown_method} = Type.from_value(0x123)
  end
end
