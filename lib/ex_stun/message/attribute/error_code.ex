defmodule ExSTUN.Message.Attribute.ErrorCode do
  @moduledoc """
  STUN Message Attribute Error-Code
  """
  alias ExSTUN.Message.RawAttribute

  @behaviour ExSTUN.Message.Attribute

  # max reason size in bytes
  @max_reason_size 20

  @attr_type 0x0009

  @type t() :: %__MODULE__{
          code: 300..699,
          reason: binary()
        }

  @enforce_keys [:code]
  defstruct @enforce_keys ++ [reason: ""]

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

  defp decode(<<0::21, class::3, num::8, reason::binary>>)
       when byte_size(reason) < @max_reason_size do
    code = 100 * class + num
    {:ok, %__MODULE__{code: code, reason: reason}}
  end

  defp decode(_data), do: {:error, :invalid_error_code}

  defp encode(%__MODULE__{code: code, reason: reason}) do
    class = div(code, 100)
    num = rem(code, 100)
    <<0::21, class::3, num::8, reason::binary>>
  end
end
