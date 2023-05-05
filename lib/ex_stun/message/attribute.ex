defmodule ExSTUN.Message.Attribute do
  @moduledoc """
  Behaviour defining a STUN attribute.

  Each module implementing this behaviour is
  expected to define its own struct that will be
  passed to `c:to_raw/2`.
  """
  alias ExSTUN.Message
  alias ExSTUN.Message.RawAttribute

  @doc """
  Returns attribute integer type.
  """
  @callback type() :: integer()

  @doc """
  Serializes an attribute.

  Message is passed as some of attributes may
  require transaction id for serialization.
  """
  @callback to_raw(attribute :: struct(), message :: Message.t()) :: RawAttribute.t()

  @doc """
  Deserializes a raw attribute.

  Message is passed as some of attributes may
  require transaction id for deserialization.
  """
  @callback from_raw(raw_attribute :: RawAttribute.t(), message :: Message.t()) ::
              {:ok, struct()} | {:error, atom()}

  @optional_callbacks type: 0, to_raw: 2, from_raw: 2
end
