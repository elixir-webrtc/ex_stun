defmodule ExSTUN.MessageTest do
  use ExUnit.Case

  import Bitwise
  alias ExSTUN.Message
  alias ExSTUN.Message.Type
  alias ExSTUN.Message.RawAttribute
  alias ExSTUN.Message.Attribute.{Realm, Software, Username}

  @m_type <<0x01::14>>
  @len <<0x00, 0x58>>
  @cookie <<0x21, 0x12, 0xA4, 0x42>>
  @transaction_id <<0xB7, 0xE7, 0xA7, 0x01, 0xBC, 0x34, 0xD6, 0x86, 0xFA, 0x87, 0xDF, 0xAE>>
  @header <<0::1, 0::1, @m_type::bitstring, @len::binary, @cookie::binary,
            @transaction_id::binary>>

  @attr_type 0x8022

  @attr_header <<@attr_type::16, 0x00, 0x10>>
  @attr <<@attr_header::binary, "STUN test client"::binary>>

  @attr_header1 <<0x80, 0x22, 0x00, 0x11>>
  @attr1 <<@attr_header1::binary, "STUN test client1"::binary, 0, 0, 0>>

  @attr_header2 <<0x80, 0x22, 0x00, 0x12>>
  @attr2 <<@attr_header2::binary, "STUN test client11"::binary, 0, 0>>

  @attr_header3 <<0x80, 0x22, 0x00, 0x13>>
  @attr3 <<@attr_header3::binary, "STUN test client111"::binary, 0>>

  @d_attr %RawAttribute{type: @attr_type, value: "STUN test client"}
  @d_attr1 %RawAttribute{type: @attr_type, value: "STUN test client1"}
  @d_attr2 %RawAttribute{type: @attr_type, value: "STUN test client11"}
  @d_attr3 %RawAttribute{type: @attr_type, value: "STUN test client111"}

  describe "Message.new" do
    setup do
      %{type: %Type{class: :request, method: :bindinf}}
    end

    test "creates valid message", %{type: type} do
      message = Message.new(type)

      assert %Message{
               type: ^type,
               transaction_id: t_id,
               attributes: []
             } = message

      assert is_integer(t_id)
    end

    test "creates message with attributed", %{type: type} do
      value = "attribute value"
      message = Message.new(type, [%Software{value: value}])

      assert %Message{
               attributes: [%RawAttribute{type: @attr_type, value: ^value}]
             } = message
    end

    test "creates message with custom transaction id", %{type: type} do
      t_id = "custom id"
      message = Message.new(t_id, type, [])

      assert %Message{
               transaction_id: ^t_id
             } = message
    end
  end

  describe "Message.decode/1" do
    test "decodes message without attributes correctly" do
      message = <<@header::binary>>

      assert {:ok, message} = Message.decode(message)
      assert_message_header(message)
    end

    test "decodes message with one attribute correctly" do
      message = <<@header::binary, @attr::binary>>

      assert {:ok, message} = Message.decode(message)
      assert_message_header(message)
      assert message.attributes == [@d_attr]
    end

    test "decodes message with multiple attributes correctly" do
      message = <<@header::binary, @attr::binary, @attr::binary>>

      assert {:ok, message} = Message.decode(message)
      assert_message_header(message)

      assert message.attributes == [@d_attr, @d_attr]
    end

    test "decodes message with mutliple attributes of different paddings correctly" do
      attributes = <<@attr::binary, @attr1::binary, @attr2::binary, @attr3::binary>>
      message = <<@header::binary, attributes::binary>>

      assert {:ok, message} = Message.decode(message)
      assert_message_header(message)

      assert message.attributes == [@d_attr, @d_attr1, @d_attr2, @d_attr3]
    end

    test "returns an error when data is less than 20 bytes" do
      assert {:error, :not_enough_data} = Message.decode(<<>>)
      assert {:error, :not_enough_data} = Message.decode(gen_bin(19))
    end

    test "returns an error when header is malformed" do
      # the last byte of magic cookie has been modified
      invalid_cookie = <<0x21, 0x12, 0xA4, 0x43>>

      message =
        <<0::1, 0::1, @m_type::bitstring, @len::binary, invalid_cookie::binary,
          @transaction_id::binary>>

      assert {:error, :malformed_header} = Message.decode(message)

      # message doesn't start with two 0 bits
      message =
        <<0::1, 1::1, @m_type::bitstring, @len::binary, @cookie::binary, @transaction_id::binary>>

      assert {:error, :malformed_header} = Message.decode(message)
    end

    test "returns an error when attribute has wrong length" do
      # software attribute
      # length greater than attribute value
      attr_header = <<0x80, 0x22, 0x00, 0x10>>
      attr = "test client"
      message = <<@header::binary, attr_header::binary, attr::binary>>

      assert {:error, :malformed_attribute} = Message.decode(message)

      # attribute header less than 4 bytes
      attr_header = <<0x80, 0x22, 0x10>>
      message = <<@header::binary, attr_header::binary>>

      assert {:error, :malformed_attribute} = Message.decode(message)
    end

    test "returns an error when attribute has wrong padding" do
      # software attribute
      attr_header = <<0x80, 0x22, 0x00, 0x0B>>
      attr = "test client"
      message = <<@header::binary, attr_header::binary, attr::binary>>

      assert {:error, :malformed_attr_padding} = Message.decode(message)
    end

    test "returns an error when there's data after fingerprint" do
      # this is not a valid fingerprint, but that does not matter here
      fingerprint = <<0x80, 0x28, 4::16, 0::32>>
      attributes = <<fingerprint::binary, @attr::binary>>

      header =
        <<0::1, 0::1, @m_type::bitstring, byte_size(attributes)::16, @cookie::binary,
          @transaction_id::binary>>

      msg = <<header::binary, attributes::binary>>

      assert {:error, :data_after_fingerprint} = Message.decode(msg)
    end

    test "ignores appropriate attributes after message integrity" do
      # this is not a valid message integrity, but that does not matter here
      msg_int = <<0x00, 0x08, 4::16, 0::32>>
      attributes = <<msg_int::binary, @attr::binary>>

      header =
        <<0::1, 0::1, @m_type::bitstring, byte_size(attributes)::16, @cookie::binary,
          @transaction_id::binary>>

      msg = <<header::binary, attributes::binary>>

      assert {:ok, message} = Message.decode(msg)
      assert_message_header(message)

      assert [%RawAttribute{type: 8}] = message.attributes
    end
  end

  describe "Message.add_attribute/2" do
    test "adds attribute to a message correctly" do
      message = Message.new(%Type{class: :request, method: :binding})
      message = Message.add_attribute(message, @d_attr)
      assert message.attributes == [@d_attr]

      message = Message.add_attribute(message, @d_attr1)
      assert message.attributes == [@d_attr, @d_attr1]
    end

    test "raises when trying to add attribute of type different than t:Attribute.t/0" do
      message = Message.new(%Type{class: :request, method: :binding})
      assert_raise FunctionClauseError, fn -> Message.add_attribute(message, 1) end
    end
  end

  describe "Message.get_attribute/2" do
    test "returns attribute when it is present in a message" do
      message = <<@header::binary, @attr::binary>>

      assert {:ok, message} = Message.decode(message)
      assert_message_header(message)

      assert {:ok, %Software{}} = Message.get_attribute(message, Software)
    end

    test "returns first attribute when there are multiple attributes of the same type" do
      attributes = <<@attr::binary, @attr1::binary, @attr2::binary, @attr3::binary>>
      message = <<@header::binary, attributes::binary>>

      assert {:ok, message} = Message.decode(message)
      assert_message_header(message)

      assert {:ok, %Software{}} = Message.get_attribute(message, Software)
    end

    test "returns nil when there is no attribute of given type" do
      message = <<@header::binary, @attr::binary>>

      assert {:ok, message} = Message.decode(message)
      assert_message_header(message)

      assert nil == Message.get_attribute(message, Realm)
    end

    test "returns nil when there are no attributes at all" do
      message = <<@header::binary>>

      assert {:ok, message} = Message.decode(message)
      assert_message_header(message)

      assert nil == Message.get_attribute(message, Software)
    end
  end

  describe "Message.encode/1" do
    test "correctly encodes the message header and an attribute" do
      <<t_id::96>> = @transaction_id
      # length of attribute = attribute header + attribute in bytes
      # length padded to 32 bits
      attr = %Software{value: <<0::32>>}
      attr_len = 8

      msg =
        %Message.Type{class: :request, method: :binding}
        |> then(&Message.new(t_id, &1, [attr]))
        |> Message.encode()

      assert <<
               0::2,
               @m_type::bitstring,
               ^attr_len::16,
               @cookie::binary,
               @transaction_id::binary,
               attr_bin::binary
             >> = msg

      assert byte_size(attr_bin) == attr_len
    end

    test "adds valid fingerprint if requested" do
      msg =
        %Message.Type{class: :request, method: :binding}
        |> Message.new()
        |> Message.with_fingerprint()
        |> Message.encode()

      <<start::binary-size(20), _attr_header::32, msg_fp::32>> = msg
      valid_fp = bxor(:erlang.crc32(start), 0x5354554E)

      assert msg_fp == valid_fp
    end

    test "adds message integrity" do
      key = "somepassword"

      # normally this message would contain the username or realm attributes
      # but it's not necessary to test the message integrity
      msg =
        %Message.Type{class: :request, method: :binding}
        |> Message.new()
        |> Message.with_integrity(key)
        |> Message.encode()

      <<start::binary-size(20), _attr_header::32, msg_it::binary>> = msg
      mac = :crypto.mac(:hmac, :sha, key, start)

      assert msg_it == mac
    end

    test "encodes attributes in a valid order" do
      msg =
        %Message.Type{class: :request, method: :binding}
        |> Message.new([%Software{value: <<0::32>>}])
        |> Message.with_fingerprint()
        |> Message.with_integrity("somekey")
        |> Message.encode()

      <<
        _header::binary-size(20),
        attr_type_1::16,
        _attr_len_1::16,
        _attr_1::binary-size(4),
        attr_type_2::16,
        _attr_len_2::16,
        _attr_2::binary-size(20),
        attr_type_3::16,
        _attr_len_3::16,
        _attr_3::binary
      >> = msg

      # first Software, then Message Integrity, then Fingerprint
      assert attr_type_1 == 0x8022
      assert attr_type_2 == 0x0008
      assert attr_type_3 == 0x8028
    end
  end

  describe "Message.authenticate_st/2" do
    test "works properly with a valid key" do
      key = "somekey"
      username = "someuser"

      encoded =
        %Message.Type{class: :request, method: :binding}
        |> Message.new([%Username{value: username}])
        |> Message.with_integrity(key)
        |> Message.encode()

      {:ok, %Message{} = decoded} = Message.decode(encoded)
      {:ok, username_attr} = Message.get_attribute(decoded, Username)

      assert username == username_attr.value
      assert {:ok, ^key} = Message.authenticate_st(decoded, key)
    end

    test "fails on invalid key" do
      encoded =
        %Message.Type{class: :request, method: :binding}
        |> Message.new([%Username{value: "username"}])
        |> Message.with_integrity("somekey")
        |> Message.encode()

      {:ok, %Message{} = decoded} = Message.decode(encoded)

      assert :error = Message.authenticate_st(decoded, "invalidkey")
    end
  end

  describe "Message.authenticate_lt/2" do
    test "works properly with valid credentials" do
      username = "someuser"
      password = "somepassword"
      realm = "somerealm"

      key = username <> ":" <> realm <> ":" <> password
      key = :crypto.hash(:md5, key)

      encoded =
        %Message.Type{class: :request, method: :binding}
        |> Message.new([
          %Username{value: username},
          %Realm{value: realm}
        ])
        |> Message.with_integrity(key)
        |> Message.encode()

      {:ok, %Message{} = decoded} = Message.decode(encoded)
      {:ok, username_attr} = Message.get_attribute(decoded, Username)

      assert username == username_attr.value
      {:ok, ^key} = Message.authenticate_lt(decoded, password)
    end

    test "fails on invalid credentials" do
      username = "someuser"
      realm = "somerealm"

      key = username <> ":" <> realm <> ":" <> "somepassowrd"
      key = :crypto.hash(:md5, key)

      encoded =
        %Message.Type{class: :request, method: :binding}
        |> Message.new([
          %Username{value: username},
          %Realm{value: realm}
        ])
        |> Message.with_integrity(key)
        |> Message.encode()

      {:ok, %Message{} = decoded} = Message.decode(encoded)

      assert :error = Message.authenticate_lt(decoded, "invalidpassword")
    end
  end

  describe "Message.check_fingerprint/1" do
    test "returns `true` on valid fingerprint" do
      encoded =
        %Message.Type{class: :request, method: :binding}
        |> Message.new()
        |> Message.with_fingerprint()
        |> Message.encode()

      {:ok, %Message{} = decoded} = Message.decode(encoded)

      assert Message.check_fingerprint(decoded)
    end

    test "fails on invalid fingerprint" do
      encoded =
        %Message.Type{class: :request, method: :binding}
        |> Message.new()
        |> Message.with_fingerprint()
        |> Message.encode()

      # modify transaction_id to malform the message
      <<begining::binary-size(8), t_id::96, rest::binary>> = encoded
      t_id = t_id + 1
      encoded = <<begining::binary, t_id::96, rest::binary>>

      {:ok, %Message{} = decoded} = Message.decode(encoded)
      assert decoded.transaction_id == t_id
      assert Message.check_fingerprint(decoded) == false
    end
  end

  defp assert_message_header(message) do
    assert message.type == %Type{class: :request, method: :binding}
    assert message.transaction_id == 56_915_807_328_848_210_473_588_875_182
  end

  defp gen_bin(len), do: :crypto.strong_rand_bytes(len)
end
