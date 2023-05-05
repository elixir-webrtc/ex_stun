defmodule ExSTUN.Message.RawAttribute do
  @moduledoc """
  STUN Message Attribute

  ```ascii
      0                   1                   2                   3
  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  |         Type                  |            Length             |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  |                         Value (variable)                ....
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

                Figure 4: Format of STUN Attributes
  ```
  """
  @type t() :: %__MODULE__{
          type: non_neg_integer(),
          value: binary()
        }

  defstruct [
    :type,
    :value
  ]

  @doc """
  Encodes attribute to binary.

  This function adds padding to align attributes on 32 bit boundary.

  ## Example

      iex> attr = %#{inspect(__MODULE__)}{type: 0x8022, value: "my_ex_stun_client"}
      iex> #{inspect(__MODULE__)}.encode(attr)
      <<0x8022::16, 17::16, "my_ex_stun_client"::binary, 0, 0, 0>>
  """
  @spec encode(t()) :: binary()
  def encode(attribute) do
    length = byte_size(attribute.value)

    padding_len = rem(4 - rem(byte_size(attribute.value), 4), 4)
    value = <<attribute.value::binary, 0::padding_len*8>>

    <<attribute.type::16, length::16, value::binary>>
  end
end
