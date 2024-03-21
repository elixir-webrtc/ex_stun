defmodule ExSTUN do
  @moduledoc """
  Module with helper functions.
  """

  @doc """
  Checks if binary is a STUN message.
  """
  @spec stun?(binary()) :: boolean()
  def stun?(<<first_byte::8, _rem_header::binary-size(19), _rest::binary>>)
      when first_byte in 0..3 do
    true
  end

  def stun?(_other), do: false
end
