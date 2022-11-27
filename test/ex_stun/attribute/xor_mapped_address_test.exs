defmodule ExStun.Message.Attribute.XORMappedAddressTest do
  use ExUnit.Case, async: true

  alias ExStun.Message
  alias ExStun.Message.Type
  alias ExStun.Message.Attribute.XORMappedAddress

  test "calling add_to_message and get_from_message gives original XORMappedAddress" do
    message = Message.new(%Type{class: :success_response, method: :binding})
    xor_address = %XORMappedAddress{family: :ipv4, port: 7878, address: {127, 0, 0, 1}}

    message = XORMappedAddress.add_to_message(message, xor_address)
    assert xor_address == XORMappedAddress.get_from_message(message)
  end
end
