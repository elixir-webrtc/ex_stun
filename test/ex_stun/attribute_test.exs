defmodule ExSTUN.Message.AttributeTest do
  use ExUnit.Case
  doctest ExSTUN.Message.RawAttribute

  alias ExSTUN.Message.RawAttribute

  test "padding is added correctly" do
    attr = %RawAttribute{type: 0x8022, value: "exclient"}
    attr = RawAttribute.encode(attr)
    assert attr == <<0x8022::16, 8::16, "exclient"::binary>>

    attr = %RawAttribute{type: 0x8022, value: "exclient111"}
    attr = RawAttribute.encode(attr)
    assert attr == <<0x8022::16, 11::16, "exclient111"::binary, 0>>

    attr = %RawAttribute{type: 0x8022, value: "exclient11"}
    attr = RawAttribute.encode(attr)
    assert attr == <<0x8022::16, 10::16, "exclient11"::binary, 0, 0>>

    attr = %RawAttribute{type: 0x8022, value: "exclient1"}
    attr = RawAttribute.encode(attr)
    assert attr == <<0x8022::16, 9::16, "exclient1"::binary, 0, 0, 0>>
  end
end
