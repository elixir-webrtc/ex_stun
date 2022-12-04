defmodule ExStun.Message.Attribute.ErrorCode do
  @moduledoc """
  STUN Message Attribute Error-Code
  """
  alias ExStun.Message

  # max reason size in bytes
  @max_reason_size 20

  @attr_type 0x0009

  @type t() :: %__MODULE__{
          code: 300..699,
          reason: binary()
        }

  @enforce_keys [:code]
  defstruct @enforce_keys ++ [reason: ""]

  @spec get_from_message(Message.t()) :: {:ok, t()} | {:error, :invalid_error_code} | nil
  def get_from_message(%Message{} = message) do
    case Message.get_attribute(message, @attr_type) do
      nil -> nil
      raw_attr -> decode(raw_attr.value)
    end
  end

  defp decode(<<0::21, class::3, num::8, reason::binary>>)
       when byte_size(reason) < @max_reason_size do
    code = 100 * class + num
    {:ok, %__MODULE__{code: code, reason: reason}}
  end

  defp decode(_data), do: {:error, :invalid_error_code}
end

defimpl ExStun.Message.Attribute, for: ExStun.Message.Attribute.ErrorCode do
  alias ExStun.Message.Attribute.ErrorCode
  alias ExStun.Message.RawAttribute

  @attr_type 0x0009

  def to_raw_attribute(attr, _msg) do
    %RawAttribute{type: @attr_type, value: encode(attr)}
  end

  defp encode(%ErrorCode{code: code, reason: reason}) do
    class = div(code, 100)
    num = rem(code, 100)
    <<0::21, class::3, num::8, reason::binary>>
  end
end
