defmodule ExStun.Message.Attribute.MappedAddress do
  @moduledoc """
  STUN Message Attribute Mapped Address

  ```ascii
  0                   1                   2                   3
  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  |0 0 0 0 0 0 0 0|    Family     |           Port                |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  |                                                               |
  |                 Address (32 bits or 128 bits)                 |
  |                                                               |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

          Figure 5: Format of MAPPED-ADDRESS Attribute
  ```
  """

  @type t() :: %__MODULE__{
          family: :ip4 | :ip6,
          port: 0..65_535,
          address: :inet.ip_address()
        }

  defstruct [
    :family,
    :port,
    :address
  ]

  def encode(%__MODULE__{family: family, port: port, address: address}) do
    with {:ok, family} <- encode_family(family),
         {:ok, port} <- encode_port(port),
         {:ok, address} <- encode_address(address) do
      value = <<0::8, family::binary, port::binary, address::binary>>
      %ExStun.Message.Attribute{type: 0x0001, value: value}
    end
  end

  def encode(_other), do: {:error, :invalid_attribute}

  def decode(<<0, family::8, port::16, address::binary>>) when byte_size(address) in [4, 16] do
    with {:ok, family} <- decode_family(family),
         {:ok, address} <- decode_address(address) do
      %__MODULE__{
        family: family,
        port: port,
        address: address
      }
    end
  end

  def decode(_other), do: {:error, :not_enough_data}

  defp encode_family(:ipv4), do: {:ok, <<0x01>>}
  defp encode_family(:ipv6), do: {:ok, <<0x02>>}
  defp encode_family(_other), do: {:error, :invalid_family}

  defp encode_port(port) when port in 0..65_535, do: {:ok, <<port::16>>}
  defp encode_port(_port), do: {:error, :invalid_port}

  defp encode_address({a, b, c, d}), do: {:ok, <<a, b, c, d>>}

  defp encode_address({a, b, c, d, e, f, g, h}),
    do: {:ok, <<a::16, b::16, c::16, d::16, e::16, f::16, g::16, h::16>>}

  defp encode_address(_other), do: {:error, :invalid_address}

  defp decode_family(0x01), do: {:ok, :ipv4}
  defp decode_family(0x02), do: {:ok, :ipv6}
  defp decode_family(_other), do: {:error, :invalid_family}

  defp decode_address(<<a, b, c, d>>), do: {:ok, {a, b, c, d}}

  defp decode_address(<<a::16, b::16, c::16, d::16, e::16, f::16, g::16, h::16>>),
    do: {:ok, {a, b, c, d, e, f, g, h}}

  defp decode_address(_other), do: {:error, :invalid_address}
end
