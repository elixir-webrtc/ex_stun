defmodule ExSTUN.Message.Attribute.Fingerprint do
  @moduledoc """
  STUN Message Attribute Fingerprint
  """
  alias ExSTUN.Message.RawAttribute

  @behaviour ExSTUN.Message.Attribute

  @attr_type 0x8028

  @type t() :: %__MODULE__{value: integer()}

  @enforce_keys [:value]
  defstruct @enforce_keys

  @impl true
  def type(), do: @attr_type

  @impl true
  def from_raw(%RawAttribute{} = raw_attr, _message) do
    decode(raw_attr.value)
  end

  @impl true
  def to_raw(%__MODULE__{} = attr, _msg) do
    %RawAttribute{type: @attr_type, value: encode(attr)}
  end

  defp decode(<<crc::32>>) do
    {:ok, %__MODULE__{value: crc}}
  end

  defp decode(_data), do: {:error, :invalid_fingerprint}

  defp encode(%__MODULE__{value: crc}), do: <<crc::32>>
end
