defmodule ExStun.Message.Attribute do
  @type t() :: %__MODULE__{
          type: non_neg_integer(),
          value: binary()
        }

  defstruct [
    :type,
    :value
  ]

  def encode(attribute) do
    length = byte_size(attribute.value)

    needed_padding = attribute.value |> byte_size() |> rem(4)
    value = add_padding(attribute.value, needed_padding)

    <<attribute.type::16, length::16, value>>
  end

  defp add_padding(data, needed_padding) do
    padding = for _i <- needed_padding, into: <<>>, do: <<0>>
    <<data, padding>>
  end
end
