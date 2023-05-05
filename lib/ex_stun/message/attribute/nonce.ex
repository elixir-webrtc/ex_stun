defmodule ExSTUN.Message.Attribute.Nonce do
  @moduledoc """
  STUN Message Attribute Nonce
  """
  alias ExSTUN.Message.RawAttribute

  @behaviour ExSTUN.Message.Attribute

  # max nonce size in bytes
  @max_nonce_size 763

  @attr_type 0x0015

  @type t() :: %__MODULE__{
          value: binary()
        }

  @enforce_keys [:value]
  defstruct @enforce_keys

  @impl true
  def type(), do: @attr_type

  @impl true
  def from_raw(%RawAttribute{} = raw_attr, _message) do
    decode(raw_attr.value)
  end

  @impl true
  def to_raw(%__MODULE__{value: value}, _msg) do
    %RawAttribute{type: @attr_type, value: value}
  end

  defp decode(data) when is_binary(data) and byte_size(data) < @max_nonce_size do
    {:ok, %__MODULE__{value: data}}
  end

  defp decode(_data), do: {:error, :invalid_nonce}
end
