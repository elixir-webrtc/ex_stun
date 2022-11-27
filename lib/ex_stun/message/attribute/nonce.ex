defmodule ExStun.Message.Attribute.Nonce do
  @moduledoc """
  STUN Message Attribute Nonce
  """
  alias ExStun.Message
  alias ExStun.Message.Attribute

  # max nonce size in bytes
  @max_nonce_size 763

  @attr_type 0x0015

  @type t() :: %__MODULE__{
          value: binary()
        }

  @enforce_keys [:value]
  defstruct @enforce_keys

  @spec add_to_message(t(), Message.t()) :: Message.t()
  def add_to_message(%__MODULE__{value: value}, message) do
    raw_attribute = %Attribute{type: @attr_type, value: value}
    Message.add_attribute(message, raw_attribute)
  end

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
