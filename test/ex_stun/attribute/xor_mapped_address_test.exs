defmodule ExSTUN.Message.Attribute.XORMappedAddressTest do
  use ExUnit.Case, async: true

  alias ExSTUN.Message
  alias ExSTUN.Message.Type
  alias ExSTUN.Message.Attribute.XORMappedAddress

  test "to_raw/2 and from_raw/2" do
    xor_address = %XORMappedAddress{family: :ipv4, port: 7878, address: {127, 0, 0, 1}}
    message = Message.new(%Type{class: :success_response, method: :binding})

    assert {:ok, xor_address} ==
             xor_address
             |> XORMappedAddress.to_raw(message)
             |> XORMappedAddress.from_raw(message)
  end
end
