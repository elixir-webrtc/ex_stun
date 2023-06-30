defmodule ExSTUN.Message.Attribute.XORMappedAddressTest do
  use ExUnit.Case, async: true

  alias ExSTUN.Message
  alias ExSTUN.Message.Attribute.XORMappedAddress
  alias ExSTUN.Message.{RawAttribute, Type}

  test "to_raw/2 and from_raw/2" do
    message = Message.new(%Type{class: :success_response, method: :binding})

    xor_address = %XORMappedAddress{port: 7878, address: {127, 0, 0, 1}}

    assert {:ok, xor_address} ==
             xor_address
             |> XORMappedAddress.to_raw(message)
             |> XORMappedAddress.from_raw(message)

    xor_address = %XORMappedAddress{port: 7878, address: {0, 0, 0, 0, 0, 0, 0, 1}}

    assert {:ok, xor_address} ==
             xor_address
             |> XORMappedAddress.to_raw(message)
             |> XORMappedAddress.from_raw(message)
  end

  test "invalid family" do
    message = Message.new(%Type{class: :success_response, method: :binding})
    # address is ipv4 but family is ipv6 
    raw_attr = %RawAttribute{type: 0x0020, value: <<0, 2, 63, 212, 94, 18, 164, 67>>}
    assert {:error, :invalid_family} = XORMappedAddress.from_raw(raw_attr, message)
    # address is ipv6 but family is ipv4
    raw_attr = %RawAttribute{
      type: 0x0020,
      value: <<0, 1, 63, 212, 0, 18, 0, 66, 0, 150, 0, 154, 0, 220, 0, 160, 0, 238, 0, 181>>
    }

    assert {:error, :invalid_family} = XORMappedAddress.from_raw(raw_attr, message)
  end
end
