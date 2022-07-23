defmodule ExStun.Message.Method do
  @moduledoc """
  STUN Message Method
  """
  @type t() :: :binding

  @doc """
  Converts method from an atom into an integer.
  """
  @spec to_value(t()) :: 0x01
  def to_value(method)

  def to_value(:binding), do: 0x01

  @doc """
  Converts method from an integer into an atom.
  """
  @spec from_value(non_neg_integer()) :: {:ok, t()} | {:error, :unknown_method}
  def from_value(value)

  def from_value(0x01), do: {:ok, :binding}
  def from_value(_other), do: {:error, :unknown_method}
end
