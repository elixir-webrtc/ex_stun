defmodule ExStun.Message.Class do
  @moduledoc """
  STUN Message Class
  """

  @type t() :: :request | :success_response | :error_response | :indication
  def encode(:request), do: 0x00
  def encode(:indication), do: 0x01
  def encode(:success_response), do: 0x02
  def encode(:error_response), do: 0x03

  def decode(0x00), do: :request
  def decode(0x01), do: :indication
  def decode(0x02), do: :success_response
  def decode(0x03), do: :error_response
end
