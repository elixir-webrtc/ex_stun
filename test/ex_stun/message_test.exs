defmodule ExSTUN.MessageTest do
  use ExUnit.Case

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

  describe "Message.encode" do
    test "short-term message integrity" do
      key = "somekey"
      username = "someuser"

      encoded =
        %Message.Type{class: :request, method: :binding}
        |> Message.new([%Message.Attribute.Username{value: username}])
        |> Message.with_integrity(key)
        |> Message.encode()

      {:ok, %Message{} = decoded} = Message.decode(encoded)
      {:ok, username_attr} = Message.get_attribute(decoded, Username)

      assert username == username_attr.value
      assert {:ok, ^key} = Message.authenticate_st(decoded, key)
    end
  end

  defp assert_message_header(message) do
    assert message.type == %Type{class: :request, method: :binding}
    assert message.transaction_id == 56_915_807_328_848_210_473_588_875_182
  end

  defp gen_bin(len), do: :crypto.strong_rand_bytes(len)
end
