defmodule ExStun.Message.Method do
  @type t() :: :binding

  @spec encode(t()) :: binary()
  def encode(binding), do: 0x01

  @spec decode(binary()) :: t()
  def decode(0x01), do: :binding
end
