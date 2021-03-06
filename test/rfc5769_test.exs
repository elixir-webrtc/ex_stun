defmodule ExStun.RFC5769Test do
  use ExUnit.Case

  test "sample request is parsed correctly" do
    # the padding for username was changed from 3x(0x20) to 3x(0x00) to be 
    # compliant with RFC 8489
    req =
      <<0x00, 0x01, 0x00, 0x58, 0x21, 0x12, 0xA4, 0x42, 0xB7, 0xE7, 0xA7, 0x01, 0xBC, 0x34, 0xD6,
        0x86, 0xFA, 0x87, 0xDF, 0xAE, 0x80, 0x22, 0x00, 0x10, 0x53, 0x54, 0x55, 0x4E, 0x20, 0x74,
        0x65, 0x73, 0x74, 0x20, 0x63, 0x6C, 0x69, 0x65, 0x6E, 0x74, 0x00, 0x24, 0x00, 0x04, 0x6E,
        0x00, 0x01, 0xFF, 0x80, 0x29, 0x00, 0x08, 0x93, 0x2F, 0xF9, 0xB1, 0x51, 0x26, 0x3B, 0x36,
        0x00, 0x06, 0x00, 0x09, 0x65, 0x76, 0x74, 0x6A, 0x3A, 0x68, 0x36, 0x76, 0x59, 0x00, 0x00,
        0x00, 0x00, 0x08, 0x00, 0x14, 0x9A, 0xEA, 0xA7, 0x0C, 0xBF, 0xD8, 0xCB, 0x56, 0x78, 0x1E,
        0xF2, 0xB5, 0xB2, 0xD3, 0xF2, 0x49, 0xC1, 0xB5, 0x71, 0xA2, 0x80, 0x28, 0x00, 0x04, 0xE5,
        0x7A, 0x3B, 0xCF>>

    assert {:ok, message} = ExStun.Message.decode(req)
    assert message.type == %ExStun.Message.Type{class: :request, method: :binding}
    assert message.transaction_id == 56_915_807_328_848_210_473_588_875_182

    assert %ExStun.Message.Attribute{type: 0x8022, value: "STUN test client"} =
             ExStun.Message.get_attribute(message, 0x8022)

    assert %ExStun.Message.Attribute{type: 0x0024, value: <<110, 0, 1, 255>>} =
             ExStun.Message.get_attribute(message, 0x0024)

    assert %ExStun.Message.Attribute{
             type: 0x8029,
             value: <<147, 47, 249, 177, 81, 38, 59, 54>>
           } = ExStun.Message.get_attribute(message, 0x8029)

    assert %ExStun.Message.Attribute{type: 0x0006, value: "evtj:h6vY"} =
             ExStun.Message.get_attribute(message, 0x0006)

    assert %ExStun.Message.Attribute{
             type: 0x0008,
             value:
               <<154, 234, 167, 12, 191, 216, 203, 86, 120, 30, 242, 181, 178, 211, 242, 73, 193,
                 181, 113, 162>>
           } = ExStun.Message.get_attribute(message, 0x0008)

    assert %ExStun.Message.Attribute{type: 0x8028, value: <<229, 122, 59, 207>>} =
             ExStun.Message.get_attribute(message, 0x8028)
  end

  test "sample ipv4 response is parsed correctly" do
    # the padding for server name was changed from 1x(0x20) to 1x(0x00) to be 
    # compliant with RFC 8489
    ipv4_resp =
      <<0x01, 0x01, 0x00, 0x3C, 0x21, 0x12, 0xA4, 0x42, 0xB7, 0xE7, 0xA7, 0x01, 0xBC, 0x34, 0xD6,
        0x86, 0xFA, 0x87, 0xDF, 0xAE, 0x80, 0x22, 0x00, 0x0B, 0x74, 0x65, 0x73, 0x74, 0x20, 0x76,
        0x65, 0x63, 0x74, 0x6F, 0x72, 0x00, 0x00, 0x20, 0x00, 0x08, 0x00, 0x01, 0xA1, 0x47, 0xE1,
        0x12, 0xA6, 0x43, 0x00, 0x08, 0x00, 0x14, 0x2B, 0x91, 0xF5, 0x99, 0xFD, 0x9E, 0x90, 0xC3,
        0x8C, 0x74, 0x89, 0xF9, 0x2A, 0xF9, 0xBA, 0x53, 0xF0, 0x6B, 0xE7, 0xD7, 0x80, 0x28, 0x00,
        0x04, 0xC0, 0x7D, 0x4C, 0x96>>

    assert {:ok, message} = ExStun.Message.decode(ipv4_resp)
    assert message.type == %ExStun.Message.Type{class: :success_response, method: :binding}
    assert message.transaction_id == 56_915_807_328_848_210_473_588_875_182

    assert %ExStun.Message.Attribute{type: 0x8022, value: "test vector"} =
             ExStun.Message.get_attribute(message, 0x8022)

    assert %ExStun.Message.Attribute{type: 0x0020, value: <<0, 1, 161, 71, 225, 18, 166, 67>>} =
             ExStun.Message.get_attribute(message, 0x0020)

    assert %ExStun.Message.Attribute{
             type: 0x0008,
             value:
               <<43, 145, 245, 153, 253, 158, 144, 195, 140, 116, 137, 249, 42, 249, 186, 83, 240,
                 107, 231, 215>>
           } = ExStun.Message.get_attribute(message, 0x0008)

    assert %ExStun.Message.Attribute{type: 0x8028, value: <<192, 125, 76, 150>>} =
             ExStun.Message.get_attribute(message, 0x8028)
  end

  test "sample ipv4 response is encoded correctly" do
    ipv4_resp =
      <<0x01, 0x01, 0x00, 0x3C, 0x21, 0x12, 0xA4, 0x42, 0xB7, 0xE7, 0xA7, 0x01, 0xBC, 0x34, 0xD6,
        0x86, 0xFA, 0x87, 0xDF, 0xAE, 0x80, 0x22, 0x00, 0x0B, 0x74, 0x65, 0x73, 0x74, 0x20, 0x76,
        0x65, 0x63, 0x74, 0x6F, 0x72, 0x00, 0x00, 0x20, 0x00, 0x08, 0x00, 0x01, 0xA1, 0x47, 0xE1,
        0x12, 0xA6, 0x43, 0x00, 0x08, 0x00, 0x14, 0x2B, 0x91, 0xF5, 0x99, 0xFD, 0x9E, 0x90, 0xC3,
        0x8C, 0x74, 0x89, 0xF9, 0x2A, 0xF9, 0xBA, 0x53, 0xF0, 0x6B, 0xE7, 0xD7, 0x80, 0x28, 0x00,
        0x04, 0xC0, 0x7D, 0x4C, 0x96>>

    assert {:ok, message} = ExStun.Message.decode(ipv4_resp)
    assert ipv4_resp == ExStun.Message.encode(message)
  end
end
