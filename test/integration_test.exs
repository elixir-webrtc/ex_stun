defmodule ExSTUN.IntegrationTest do
  use ExUnit.Case, async: true

  alias ExSTUN.Message
  alias ExSTUN.Message.Type
  alias ExSTUN.Message.Attribute.XORMappedAddress

  test "binding request/response" do
    {:ok, socket} = :gen_udp.open(0, [{:active, false}, :binary])

    req =
      %Type{class: :request, method: :binding}
      |> Message.new()
      |> Message.encode()

    :ok = :gen_udp.send(socket, ~c"stun.l.google.com", 19_302, req)
    {:ok, {_, _, resp}} = :gen_udp.recv(socket, 0)

    {:ok, %Message{} = msg} = Message.decode(resp)
    assert {:ok, %XORMappedAddress{}} = Message.get_attribute(msg, XORMappedAddress)
  end
end
