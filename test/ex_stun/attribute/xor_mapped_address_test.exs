defmodule ExSTUN.Message.Attribute.XORMappedAddressTest do
  use ExUnit.Case, async: true

  alias ExSTUN.Message
  alias ExSTUN.Message.Type
  alias ExSTUN.Message.Attribute.XORMappedAddress

  test "calling add_to_message and get_from_message gives original XORMappedAddress" do
    xor_address = %XORMappedAddress{family: :ipv4, port: 7878, address: {127, 0, 0, 1}}
    message = Message.new(%Type{class: :success_response, method: :binding}, [xor_address])
    assert {:ok, xor_address} == Message.get_attribute(message, XORMappedAddress)
  end
end
