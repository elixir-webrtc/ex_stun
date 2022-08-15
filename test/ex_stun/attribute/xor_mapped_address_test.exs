defmodule ExStun.Message.Attribute.XORMappedAddressTest do
  use ExUnit.Case, async: true

  alias ExStun.Message
  alias ExStun.Message.Type
  alias ExStun.Message.Attribute.XORMappedAddress

  test "encoding and decoding gives original XORMappedAddress" do
    message = Message.new(%Type{class: :success_response, method: :binding})
    xor_address = %XORMappedAddress{family: :ipv4, port: 7878, address: {127, 0, 0, 1}}

    raw_attr = XORMappedAddress.to_raw_attribute(xor_address, message)
    message = Message.add_attribute(message, raw_attr)
    assert xor_address == XORMappedAddress.get_from_message(message)
  end
end
