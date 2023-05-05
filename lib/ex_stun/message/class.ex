defmodule ExSTUN.Message.Class do
  @moduledoc """
  STUN Message Class
  """

  @type t() :: :request | :success_response | :error_response | :indication

  @doc """
  Converts class from an atom into an integer.
  """
  @spec to_value(t()) :: 0x00 | 0x01 | 0x02 | 0x03
  def to_value(class)

  def to_value(:request), do: 0x00
  def to_value(:indication), do: 0x01
  def to_value(:success_response), do: 0x02
  def to_value(:error_response), do: 0x03

  @doc """
  Converts class from an integer into an atom.
  """
  @spec from_value(non_neg_integer()) :: {:ok, t()} | {:error, :unknown_class}
  def from_value(value)

  def from_value(0x00), do: {:ok, :request}
  def from_value(0x01), do: {:ok, :indication}
  def from_value(0x02), do: {:ok, :success_response}
  def from_value(0x03), do: {:ok, :error_response}
  def from_value(_other), do: {:error, :unknown_class}
end
