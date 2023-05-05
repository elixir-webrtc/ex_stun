defmodule ExSTUN.Message do
  @moduledoc """
  STUN Message

  ```ascii
        0                   1                   2                   3
      0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |0 0|     STUN Message Type     |         Message Length        |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |                         Magic Cookie                          |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |                                                               |
     |                     Transaction ID (96 bits)                  |
     |                                                               |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

                  Figure 2: Format of STUN Message Header
  ```
  """
  alias ExSTUN.Message.Attribute.{MessageIntegrity, Realm, Username}
  alias ExSTUN.Message.{RawAttribute, Type}

  @magic_cookie 0x2112A442

  @typedoc """
  Possible `decode/1` error reasons.

  * `:not_enough_data` - provided binary is less than 20 bytes
  * `:malformed_header` - improper message header e.g. invalid cookie
  * `:unknown_method` - unknown message type method
  * `:malformed_attr_padding` - one or more attributes are not followed by
  long enough padding or padding is not 0.
  """
  @type decode_error_t() ::
          :not_enough_data
          | :malformed_header
          | :malformed_type
          | :malformed_attr_padding

  @type t() :: %__MODULE__{
          type: Type.t(),
          transaction_id: integer(),
          attributes: [RawAttribute.t()],
          len_to_int: integer(),
          raw: binary()
        }

  @enforce_keys [:type, :transaction_id]
  defstruct @enforce_keys ++ [attributes: [], len_to_int: 0, raw: <<>>]

  @doc """
  Creates a new STUN message with a random transaction id.
  """
  @spec new(Type.t(), [struct()]) :: t()
  def new(%Type{} = type, attributes \\ []) do
    do_new(new_transaction_id(), type, attributes)
  end

  @doc """
  Creates a new STUN message.
  """
  @spec new(integer(), Type.t(), [struct()]) :: t()
  def new(transaction_id, %Type{} = type, attributes) do
    do_new(transaction_id, type, attributes)
  end

  defp do_new(tid, %Type{} = type, attributes) do
    msg = %__MODULE__{
      type: type,
      transaction_id: tid
    }

    raw_attributes = Enum.map(attributes, fn %attr_mod{} = attr -> attr_mod.to_raw(attr, msg) end)
    %__MODULE__{msg | attributes: raw_attributes}
  end

  @doc """
  Encodes a STUN message into a binary.
  """
  @spec encode(t()) :: binary()
  def encode(message) do
    type = Type.to_value(message.type)
    attributes = encode_attributes(message.attributes)
    length = byte_size(attributes)

    <<0::1, 0::1, type::14, length::16, @magic_cookie::32, message.transaction_id::96,
      attributes::binary>>
  end

  @doc """
  Encodes a STUN message adding message integrity attribute.

  `key` is the key used for calculating message integrity
  and can be obtained from `authenticate/2`.
  """
  def encode_with_int(message, key) do
    text = encode(message)

    <<pre::binary-size(2), length::16, post::binary>> = text
    length = length + 24
    text = <<pre::binary, length::16, post::binary>>
    mac = :crypto.mac(:hmac, :sha, key, text)
    integrity = %MessageIntegrity{value: mac}
    raw_integrity = MessageIntegrity.to_raw(integrity, message)
    add_attribute(message, raw_integrity) |> encode()
  end

  @doc """
  Decodes a binary into a STUN message.
  """
  @spec decode(binary()) :: {:ok, t()} | {:error, decode_error_t()}
  def decode(raw)

  def decode(raw) when byte_size(raw) < 20 do
    {:error, :not_enough_data}
  end

  def decode(
        <<0::1, 0::1, type::14, _len::16, @magic_cookie::32, transaction_id::96,
          attributes::binary>> = msg
      ) do
    with {:ok, type} <- Type.from_value(type),
         {:ok, len_to_int, attributes} <- decode_attributes(attributes) do
      {:ok,
       %__MODULE__{
         type: type,
         transaction_id: transaction_id,
         attributes: attributes,
         len_to_int: len_to_int,
         raw: msg
       }}
    end
  end

  def decode(_other), do: {:error, :malformed_header}

  @doc """
  Adds attribute to a message.
  """
  @spec add_attribute(t(), RawAttribute.t()) :: t()
  def add_attribute(message, %RawAttribute{} = attr) do
    %__MODULE__{message | attributes: message.attributes ++ [attr]}
  end

  @doc """
  Gets first attribute of given type from a message.

  `attr_mod` is a module implementing `ExSTUN.Message.Attribute` behaviour.
  Returns `nil` if there is no attribute of given type.
  """
  @spec get_attribute(t(), module()) :: {:ok, struct()} | {:error, atom()} | nil
  def get_attribute(message, attr_mod) do
    case Enum.find(message.attributes, &(&1.type == attr_mod.type())) do
      nil -> nil
      raw_attr -> attr_mod.from_raw(raw_attr, message)
    end
  end

  @doc """
  Authenticates a message.

  `password` depends on the STUN authentication method and has to
  be provided from the outside.

  `key` is a key used for calculating MAC and can be used
  for adding message integrity in a response. See `encode_with_int/2`.
  """
  @spec authenticate(t(), binary()) :: {:ok, key :: binary()} | :error
  def authenticate(msg, password) do
    {:ok, %MessageIntegrity{} = msg_int} = get_attribute(msg, MessageIntegrity)
    {:ok, %Username{value: username}} = get_attribute(msg, Username)
    {:ok, %Realm{value: realm}} = get_attribute(msg, Realm)

    key = username <> ":" <> realm <> ":" <> password
    key = :crypto.hash(:md5, key)

    # + 20 for STUN message header
    # - 24 for message integrity
    len = msg.len_to_int + 20 - 24
    <<msg_without_integrity::binary-size(len), _rest::binary>> = msg.raw
    <<pre_len::binary-size(2), _len::16, post_len::binary>> = msg_without_integrity
    msg_without_integrity = <<pre_len::binary, msg.len_to_int::16, post_len::binary>>

    mac = :crypto.mac(:hmac, :sha, key, msg_without_integrity)

    if mac == msg_int.value do
      {:ok, key}
    else
      :error
    end
  end

  defp new_transaction_id() do
    <<t_id::12*8>> = :crypto.strong_rand_bytes(12)
    t_id
  end

  defp encode_attributes([]), do: <<>>

  defp encode_attributes(attributes) do
    for attribute <- attributes, into: <<>> do
      RawAttribute.encode(attribute)
    end
  end

  defp decode_attributes(attributes, acc \\ {0, false, []})

  defp decode_attributes(<<>>, {_len_to_int, false, attrs}), do: {:ok, 0, attrs}
  defp decode_attributes(<<>>, {len_to_int, true, attrs}), do: {:ok, len_to_int, attrs}

  defp decode_attributes(raw_attrs, {len_to_int, found_int, dec_attrs}) do
    with {:ok, attr, len, is_int, rest} <- decode_next_attr(raw_attrs) do
      if found_int do
        decode_attributes(rest, {len_to_int, found_int, dec_attrs ++ [attr]})
      else
        decode_attributes(rest, {len_to_int + len, is_int, dec_attrs ++ [attr]})
      end
    end
  end

  defp decode_next_attr(<<type::16, len::16, value::binary-size(len), rest::binary>>) do
    # attributes are alligned to 32 bits
    padding_len = rem(4 - rem(len, 4), 4)

    with {:ok, rest} <- strip_padding(rest, padding_len) do
      attr = %RawAttribute{type: type, value: value}
      # 0x0008 is message integrity
      {:ok, attr, len + padding_len + 4, type == 0x0008, rest}
    end
  end

  defp decode_next_attr(_other), do: {:error, :malformed_attribute}

  defp strip_padding(data, padding_len) when byte_size(data) >= padding_len do
    case data do
      # this is not compliant with RFC 5389
      # RFC 5389 allows padding bits to be any value
      <<0::padding_len*8, rest::binary>> -> {:ok, rest}
      _other -> {:error, :malformed_attr_padding}
    end
  end

  defp strip_padding(_data, _padding_len), do: {:error, :malformed_attr_padding}
end
