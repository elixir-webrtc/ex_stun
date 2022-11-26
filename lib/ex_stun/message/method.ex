defmodule ExStun.Message.Method do
  @moduledoc """
  STUN Message Method
  """
  @type t() ::
          :binding
          # RFC 8656
          | :allocate
          | :refresh
          | :send
          | :data
          | :create_permission
          | :channel_bind

  @doc """
  Converts method from an atom into an integer.
  """
  @spec to_value(t()) :: 0x01
  def to_value(method)

  def to_value(:binding), do: 0x01
  def to_value(:allocate), do: 0x03
  def to_value(:refresh), do: 0x04
  def to_value(:send), do: 0x06
  def to_value(:data), do: 0x07
  def to_value(:create_permission), do: 0x08
  def to_value(:channel_bind), do: 0x09

  @doc """
  Converts method from an integer into an atom.
  """
  @spec from_value(non_neg_integer()) :: {:ok, t()} | {:error, :unknown_method}
  def from_value(value)

  def from_value(0x01), do: {:ok, :binding}
  def from_value(0x03), do: {:ok, :allocate}
  def from_value(0x04), do: {:ok, :refresh}
  def from_value(0x06), do: {:ok, :send}
  def from_value(0x07), do: {:ok, :data}
  def from_value(0x08), do: {:ok, :create_permission}
  def from_value(0x09), do: {:ok, :channel_bind}
  def from_value(_other), do: {:error, :unknown_method}
end
