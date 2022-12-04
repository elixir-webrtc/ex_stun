defmodule ExStun.Message.Attribute.Realm do
  @moduledoc """
  STUN Message Attribute Realm
  """
  alias ExStun.Message
  alias ExStun.Message.RawAttribute

  # max realm size in bytes
  @max_realm_size 763

  @attr_type 0x0014

  @type t() :: %__MODULE__{
          value: binary()
        }

  @enforce_keys [:value]
  defstruct @enforce_keys

  @spec get_from_message(Message.t()) :: {:ok, t()} | {:error, :invalid_realm} | nil
  def get_from_message(%Message{} = message) do
    case Message.get_attribute(message, @attr_type) do
      nil -> nil
      raw_attr -> decode(raw_attr.value)
    end
  end

  defp decode(data) when is_binary(data) and byte_size(data) < @max_realm_size do
    {:ok, %__MODULE__{value: data}}
  end

  defp decode(_data), do: {:error, :invalid_realm}
end

defimpl ExStun.Message.Attribute, for: ExStun.Message.Attribute.Realm do
  alias ExStun.Message.Attribute.Realm
  alias ExStun.Message.RawAttribute

  @attr_type 0x0014

  def to_raw_attribute(%Realm{value: value}, _msg) do
    %RawAttribute{type: @attr_type, value: value}
  end
end
