defmodule ExStun.Message.Attribute.MessageIntegrity do
  @moduledoc """
  STUN Message Attribute Message-Integrity
  """
  alias ExStun.Message
  alias ExStun.Message.RawAttribute

  # max message integrity size in bytes
  @max_message_integrity_size 20

  @attr_type 0x0008

  @type t() :: %__MODULE__{
          value: binary()
        }

  @enforce_keys [:value]
  defstruct @enforce_keys

  @spec get_from_message(Message.t()) :: {:ok, t()} | {:error, :invalid_message_integrity} | nil
  def get_from_message(%Message{} = message) do
    case Message.get_attribute(message, @attr_type) do
      nil -> nil
      raw_attr -> decode(raw_attr.value)
    end
  end

  defp decode(data) when is_binary(data) and byte_size(data) <= @max_message_integrity_size do
    {:ok, %__MODULE__{value: data}}
  end

  defp decode(_data), do: {:error, :invalid_message_integrity}
end

defimpl ExStun.Message.Attribute, for: ExStun.Message.Attribute.MessageIntegrity do
  alias ExStun.Message.Attribute.MessageIntegrity
  alias ExStun.Message.RawAttribute

  @attr_type 0x0008

  def to_raw_attribute(%MessageIntegrity{value: value}, _msg) do
    %RawAttribute{type: @attr_type, value: value}
  end
end
