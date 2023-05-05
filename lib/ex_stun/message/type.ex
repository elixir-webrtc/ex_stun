defmodule ExSTUN.Message.Type do
  @moduledoc """
  STUN Message Type

  ```ascii
          0                 1
          2  3  4 5 6 7 8 9 0 1 2 3 4 5
         +--+--+-+-+-+-+-+-+-+-+-+-+-+-+
         |M |M |M|M|M|C|M|M|M|C|M|M|M|M|
         |11|10|9|8|7|1|6|5|4|0|3|2|1|0|
         +--+--+-+-+-+-+-+-+-+-+-+-+-+-+
   Figure 3: Format of STUN Message Type Field
  ```
  """
  import Bitwise

  alias ExSTUN.Message.{Class, Method}

  @type t() :: %__MODULE__{
          class: Class.t(),
          method: Method.t()
        }

  defstruct [
    :class,
    :method
  ]

  @doc """
  Converts type into an integer.
  """
  @spec to_value(t()) :: non_neg_integer()
  def to_value(type) do
    c = Class.to_value(type.class)
    m = Method.to_value(type.method)

    a = m &&& 0b000000001111
    b = m &&& 0b000001110000
    d = m &&& 0b111110000000

    c0 = (c &&& 0b01) <<< 4
    c1 = (c &&& 0b10) <<< 7

    a + c0 + (b <<< 1) + c1 + (d <<< 2)
  end

  @doc """
  Converts integer into a type.
  """
  @spec from_value(non_neg_integer()) :: {:ok, t()} | {:error, :malformed_type}
  def from_value(value) when value in 0..((2 <<< 14) - 1) do
    <<a::5, c0::1, b::3, c1::1, d::4>> = <<value::14>>

    <<class::2>> = <<c0::1, c1::1>>
    <<method::12>> = <<a::5, b::3, d::4>>

    with {:ok, class} <- Class.from_value(class),
         {:ok, method} <- Method.from_value(method) do
      {:ok, %__MODULE__{class: class, method: method}}
    end
  end

  def from_value(_other), do: {:error, :malformed_type}
end
