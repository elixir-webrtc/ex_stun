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

  alias ExStun.Message.{Attribute, Type}

  @magic_cookie 0x2112A442

  @type t() :: %__MODULE__{
          type: Type.t(),
          transaction_id: integer(),
          attributes: [Attribute.t()]
        }

  defstruct [
    :type,
    :transaction_id,
    attributes: []
  ]

  def new(type) do
    %__MODULE__{
      type: type,
      transaction_id: new_transaction_id()
    }
  end

  @spec encode(t()) :: binary()
  def encode(message) do
    type = Type.encode(message.type)

    attributes =
      for attribute <- message.attributes, into: <<>> do
        Attribute.encode(attribute)
      end

    length = byte_size(attributes)
    <<0::1, 0::1, type::bitstring, length::16, @magic_cookie::32, message.transaction_id::binary>>
  end

  @spec decode(binary()) :: {:ok, t()} | {:error, term()}
  def decode(raw)

  def decode(raw) when byte_size(raw) < 20 do
    {:error, :not_enough_data}
  end

  def decode(
        <<0::1, 0::1, type::14, _len::16, @magic_cookie::32, transaction_id::96,
          _attributes::binary>>
      ) do
    type = Type.decode(<<type::14>>)
    attributes = []

    %__MODULE__{
      type: type,
      transaction_id: transaction_id,
      attributes: attributes
    }
  end

  def decode(_other), do: {:error, :malformed_packet}

  def add_attribute(message, attr) do
    %__MODULE__{message | attributes: message.attributes ++ [attr]}
  end

  def get_attribute(message, attr_type) do
    Enum.find(message.attributes, &(&1.type == attr_type))
  end

  def get_attributes(message, attr_type) do
    Enum.filter(message.attributes, &(&1.type == attr_type))
  end

  defp new_transaction_id() do
    :crypto.strong_rand_bytes(12)
  end
end
