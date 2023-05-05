defmodule ExSTUN.Message.Attribute.XORMappedAddress do
  @moduledoc """
  STUN Message Attribute XOR Mapped Address

  ```ascii
  0                   1                   2                   3
  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  |0 0 0 0 0 0 0 0|    Family     |         X-Port                |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  |                X-Address (Variable)                           |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

          Figure 6: Format of XOR-MAPPED-ADDRESS Attribute
  ```
  """
  import Bitwise
  alias ExSTUN.Message
  alias ExSTUN.Message.RawAttribute

  @behaviour ExSTUN.Message.Attribute

  @attr_type 0x0020
  @magic_cookie 0x2112A442

  @type t() :: %__MODULE__{
          family: :ipv4 | :ipv6,
          port: 0..65_535,
          address: :inet.ip_address()
        }

  @enforce_keys [:family, :port, :address]
  defstruct @enforce_keys

  @impl true
  def from_raw(%RawAttribute{value: value}, %Message{} = msg) do
    decode(value, msg)
  end

  @impl true
  def to_raw(%__MODULE__{} = xor_addr, %Message{} = msg) do
    %RawAttribute{type: @attr_type, value: encode(xor_addr, msg)}
  end

  @impl true
  def type(), do: @attr_type

  defp decode(<<0, family::8, x_port::16, x_address::binary>>, message)
       when byte_size(x_address) in [4, 16] do
    with {:ok, family} <- decode_family(family),
         {:ok, port} <- decode_port(x_port),
         {:ok, address} <- decode_address(x_address, message) do
      {:ok,
       %__MODULE__{
         family: family,
         port: port,
         address: address
       }}
    end
  end

  defp decode(_other, _message), do: {:error, :not_enough_data}

  defp decode_family(0x01), do: {:ok, :ipv4}
  defp decode_family(0x02), do: {:ok, :ipv6}
  defp decode_family(_other), do: {:error, :invalid_family}

  defp decode_port(x_port) do
    port = bxor(x_port, @magic_cookie >>> 16)
    if port in 0..65_535, do: {:ok, port}, else: {:error, :invalid_port}
  end

  defp decode_address(<<a, b, c, d>>, _message) do
    {:ok, bxor_address({a, b, c, d})}
  end

  defp decode_address(<<a::16, b::16, c::16, d::16, e::16, f::16, g::16, h::16>>, message) do
    <<cookie_trans_id::128>> = <<@magic_cookie::32, message.transaction_id::96>>
    {:ok, bxor_address({a, b, c, d, e, f, g, h}, cookie_trans_id)}
  end

  defp decode_address(_other, _message), do: {:error, :invalid_address}

  defp encode(%__MODULE__{} = xor_address, message) do
    <<cookie_trans_id::128>> = <<@magic_cookie::32, message.transaction_id::96>>

    family =
      case xor_address.family do
        :ipv4 -> 0x01
        :ipv6 -> 0x02
      end

    x_port = bxor(xor_address.port, @magic_cookie >>> 16)

    x_address =
      cond do
        :inet.is_ipv4_address(xor_address.address) ->
          {x_a, x_b, x_c, x_d} = bxor_address(xor_address.address)
          <<x_a, x_b, x_c, x_d>>

        :inet.is_ipv6_address(xor_address.address) ->
          {x_a, x_b, x_c, x_d, x_e, x_f, x_g, x_h} =
            bxor_address(xor_address.address, cookie_trans_id)

          <<x_a, x_b, x_c, x_d, x_e, x_f, x_g, x_h>>
      end

    <<0, family, x_port::16, x_address::binary>>
  end

  defp bxor_address({a, b, c, d}) do
    a = bxor(a, @magic_cookie >>> 24 &&& 0b11111111)
    b = bxor(b, @magic_cookie >>> 16 &&& 0b11111111)
    c = bxor(c, @magic_cookie >>> 8 &&& 0b11111111)
    d = bxor(d, @magic_cookie &&& 0b11111111)
    {a, b, c, d}
  end

  defp bxor_address({a, b, c, d, e, f, g, h}, cookie_trans_id) do
    x_a = bxor(a, cookie_trans_id >>> 112 &&& 0b11111111)
    x_b = bxor(b, cookie_trans_id >>> 96 &&& 0b11111111)
    x_c = bxor(c, cookie_trans_id >>> 80 &&& 0b11111111)
    x_d = bxor(d, cookie_trans_id >>> 64 &&& 0b11111111)
    x_e = bxor(e, cookie_trans_id >>> 48 &&& 0b11111111)
    x_f = bxor(f, cookie_trans_id >>> 32 &&& 0b11111111)
    x_g = bxor(g, cookie_trans_id >>> 16 &&& 0b11111111)
    x_h = bxor(h, cookie_trans_id &&& 0b11111111)
    {x_a, x_b, x_c, x_d, x_e, x_f, x_g, x_h}
  end
end
