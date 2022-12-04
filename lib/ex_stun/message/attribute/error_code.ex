defmodule ExStun.Message.Attribute.ErrorCode do
  @moduledoc """
  STUN Message Attribute Error-Code
  """
  alias ExStun.Message
  alias ExStun.Message.RawAttribute

  # max reason size in bytes
  @max_reason_size 20

  @attr_type 0x0009

  @type t() :: %__MODULE__{
          code: 300..699,
          reason: binary()
        }

  @enforce_keys [:code]
  defstruct @enforce_keys ++ [reason: ""]

  @spec add_to_message(t(), Message.t()) :: Message.t()
  def add_to_message(%__MODULE__{} = attr, message) do
    raw_attribute = %RawAttribute{type: @attr_type, value: encode(attr)}
    Message.add_attribute(message, raw_attribute)
  end

  @spec get_from_message(Message.t()) :: {:ok, t()} | {:error, :invalid_error_code} | nil
  def get_from_message(%Message{} = message) do
    case Message.get_attribute(message, @attr_type) do
      nil -> nil
      raw_attr -> decode(raw_attr.value)
    end
  end

  defp encode(%__MODULE__{code: code, reason: reason}) do
    class = div(code, 100)
    num = rem(code, 100)
    <<0::21, class::3, num::8, reason::binary>>
  end

  defp decode(<<0::21, class::3, num::8, reason::binary>>)
       when byte_size(reason) < @max_reason_size do
    code = 100 * class + num
    {:ok, %__MODULE__{code: code, reason: reason}}
  end

  defp decode(_data), do: {:error, :invalid_error_code}
end
