defmodule ExStun.Message.Type do
  use Bitwise

  alias ExStun.Message.{Class, Method}

  #         0                 1
  #         2  3  4 5 6 7 8 9 0 1 2 3 4 5
  #        +--+--+-+-+-+-+-+-+-+-+-+-+-+-+
  #        |M |M |M|M|M|C|M|M|M|C|M|M|M|M|
  #        |11|10|9|8|7|1|6|5|4|0|3|2|1|0|
  #        +--+--+-+-+-+-+-+-+-+-+-+-+-+-+
  #  Figure 3: Format of STUN Message Type Field

  @type t() :: %__MODULE__{
          class: Class.t(),
          method: Method.t()
        }

  defstruct [
    :class,
    :method
  ]

  @spec encode(t()) :: binary()
  def encode(type) do
    c = Class.encode(type.class)
    m = Method.encode(type.method)

    a = m &&& 0b000000001111
    b = m &&& 0b000001110000
    d = m &&& 0b111110000000

    c0 = (c &&& 0b01) <<< 4
    c1 = (c &&& 0b10) <<< 7

    (a + c0 + (b <<< 1) + c1 + (d <<< 2))
    |> then(&<<&1::14>>)
  end

  @spec decode(binary()) :: t()
  def decode(<<a::5, c0::1, b::3, c1::1, d::4>>) do
    <<class::2>> = <<c0::1, c1::1>>
    <<method::12>> = <<a::5, b::3, d::4>>

    class = Class.decode(class)
    method = Method.decode(method)

    %__MODULE__{class: class, method: method}
  end

  def decode(_other), do: {:error, :malformed_type}
end
