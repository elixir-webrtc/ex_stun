defmodule ExStun.Message.Attribute.Nonce do
  @moduledoc """
  STUN Message Attribute Nonce
  """
  alias ExStun.Message
  alias ExStun.Message.RawAttribute

  # max nonce size in bytes
  @max_nonce_size 763

  @attr_type 0x0015

  @type t() :: %__MODULE__{
          value: binary()
        }

  @enforce_keys [:value]
  defstruct @enforce_keys

  @spec get_from_message(Message.t()) :: t() | nil
  def get_from_message(%Message{} = message) do
    case Message.get_attribute(message, @attr_type) do
      nil -> nil
      raw_attr -> decode(raw_attr.value)
    end
  end

  defp decode(data) when is_binary(data) and byte_size(data) < @max_nonce_size do
    {:ok, %__MODULE__{value: data}}
  end

  defp decode(_data), do: {:error, :invalid_nonce}
end

defimpl ExStun.Message.Attribute, for: ExStun.Message.Attribute.Nonce do
  alias ExStun.Message.Attribute.Nonce
  alias ExStun.Message.RawAttribute

  @attr_type 0x0015

  def to_raw_attribute(%Nonce{value: value}, _msg) do
    %RawAttribute{type: @attr_type, value: value}
  end
end
