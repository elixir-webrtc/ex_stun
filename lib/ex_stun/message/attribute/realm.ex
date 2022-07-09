defmodule ExStun.Message.Attribute.Realm do
  @moduledoc """
  STUN Message Attribute Realm
  """
  alias ExStun.Message.Attribute

  # max realm size in bytes
  @max_realm_size 763

  @type t() :: %__MODULE__{
          value: binary()
        }

  defstruct [:value]

  @spec encode(t()) :: Attribute.t()
  def encode(%__MODULE__{value: value}) do
    %Attribute{type: 0x0014, value: value}
  end

  @spec decode(binary()) :: {:ok, Attribute.t()} | {:error, :invalid_realm}
  def decode(data) when is_binary(data) and byte_size(data) < @max_realm_size do
    {:ok, %__MODULE__{value: data}}
  end

  def decode(_data), do: {:error, :invalid_realm}
end
