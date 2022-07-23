defmodule ExStun.Message.AttributeTest do
  use ExUnit.Case
  doctest ExStun.Message.Attribute

  alias ExStun.Message.Attribute

  test "padding is added correctly" do
    attr = %ExStun.Message.Attribute{type: 0x8022, value: "exclient"}
    attr = Attribute.encode(attr)
    assert attr == <<0x8022::16, 8::16, "exclient"::binary>>

    attr = %ExStun.Message.Attribute{type: 0x8022, value: "exclient111"}
    attr = Attribute.encode(attr)
    assert attr == <<0x8022::16, 11::16, "exclient111"::binary, 0>>

    attr = %ExStun.Message.Attribute{type: 0x8022, value: "exclient11"}
    attr = Attribute.encode(attr)
    assert attr == <<0x8022::16, 10::16, "exclient11"::binary, 0, 0>>

    attr = %ExStun.Message.Attribute{type: 0x8022, value: "exclient1"}
    attr = Attribute.encode(attr)
    assert attr == <<0x8022::16, 9::16, "exclient1"::binary, 0, 0, 0>>
  end
end
