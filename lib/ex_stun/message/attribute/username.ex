defmodule ExSTUN.Message.Attribute.Username do
  @moduledoc """
  STUN Message Attribute Username
  """
  alias ExSTUN.Message.RawAttribute

  @behaviour ExSTUN.Message.Attribute

  # max username size in bytes
  @max_username_size 763

  @attr_type 0x0006

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

  defp decode(data) when is_binary(data) and byte_size(data) < @max_username_size do
    {:ok, %__MODULE__{value: data}}
  end

  defp decode(_data), do: {:error, :invalid_username}
end
