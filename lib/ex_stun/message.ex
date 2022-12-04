defmodule ExStun.Message do
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
  use Bitwise

  alias ExStun.Message.Attribute
  alias ExStun.Message.{RawAttribute, Type}

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
          raw: binary()
        }

  @enforce_keys [:type, :transaction_id]
  defstruct @enforce_keys ++ [attributes: [], raw: <<>>]

  @doc """
  Creates a new STUN message with a random transaction id.
  """
  @spec new(Type.t(), [Attribute.t()]) :: t()
  def new(%Type{} = type, attributes \\ []) do
    do_new(new_transaction_id(), type, attributes)
  end

  @doc """
  Creates a new STUN message.
  """
  @spec new(integer(), Type.t(), [Attribute.t()]) :: t()
  def new(transaction_id, %Type{} = type, attributes) do
    do_new(transaction_id, type, attributes)
  end

  defp do_new(tid, %Type{} = type, attributes) do
    msg = %__MODULE__{
      type: type,
      transaction_id: tid
    }

    raw_attributes = Enum.map(attributes, &Attribute.to_raw_attribute(&1, msg))
    %__MODULE__{msg | attributes: raw_attributes}
  end

  @doc """
  Encodes a STUN message a into binary.
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
         {:ok, attributes} <- decode_attributes(attributes) do
      {:ok,
       %__MODULE__{
         type: type,
         transaction_id: transaction_id,
         attributes: attributes,
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

  Returns `nil` if there is no attribute of given type.
  """
  @spec get_attribute(t(), non_neg_integer()) :: RawAttribute.t() | nil
  def get_attribute(message, attr_type) do
    Enum.find(message.attributes, &(&1.type == attr_type))
  end

  @doc """
  Gets all attributes of given type from a message.

  Returns empty list if there is no attribute of given type.
  """
  @spec get_attributes(t(), non_neg_integer()) :: [RawAttribute.t()]
  def get_attributes(message, attr_type) do
    Enum.filter(message.attributes, &(&1.type == attr_type))
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

  defp decode_attributes(attributes, acc \\ [])

  defp decode_attributes(<<>>, acc), do: {:ok, acc}

  defp decode_attributes(attributes, acc) do
    with {:ok, attr, rest} <- decode_next_attr(attributes) do
      decode_attributes(rest, acc ++ [attr])
    end
  end

  defp decode_next_attr(<<type::16, len::16, value::binary-size(len), rest::binary>>) do
    # attributes are alligned to 32 bits
    padding_len = rem(4 - rem(len, 4), 4)

    with {:ok, rest} <- strip_padding(rest, padding_len) do
      attr = %RawAttribute{type: type, value: value}
      {:ok, attr, rest}
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
