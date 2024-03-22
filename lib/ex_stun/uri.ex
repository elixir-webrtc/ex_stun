defmodule ExSTUN.URI do
  @moduledoc """
  Module representing STUN/TURN URI.

  Implementation of RFC 7064 and RFC 7065.

  We could try to use URI module from Elixir
  but RFC 7064 and RFC 7065 state:

    While these two ABNF productions are defined in [RFC3986]
    as components of the generic hierarchical URI, this does
    not imply that the "stun" and "stuns" URI schemes are
    hierarchical URIs.  Developers MUST NOT use a generic
    hierarchical URI parser to parse a "stun" or "stuns" URI.

  """

  @type scheme :: :stun | :stuns | :turn | :turns

  @type transport :: :udp | :tcp

  @typedoc """
  Type describing URI struct.

  `transport` denotes protocol that should be used
  by a client to connect to the STUN/TURN server.
  `nil` means that the client should try to connect with every protocol it supports.
  If scheme indicates secure connection, transport is always set to `:tcp`.
  This is based on [RFC 5928, sec. 3](https://datatracker.ietf.org/doc/html/rfc5928#section-3).
  """
  @type t() :: %__MODULE__{
          scheme: scheme(),
          host: String.t(),
          port: :inet.port_number(),
          transport: transport() | nil
        }

  @enforce_keys [:scheme, :host, :port]
  defstruct @enforce_keys ++ [:transport]

  @default_udp_tcp_port 3478
  @default_tls_port 5349

  @doc """
  The same as parse/1 but raises on error.
  """
  @spec parse!(String.t()) :: t()
  def parse!(uri) do
    case parse(uri) do
      {:ok, uri} -> uri
      :error -> raise "Invalid URI"
    end
  end

  @doc """
  Parses URI string into `t:t/0`.
  """
  @spec parse(String.t()) :: {:ok, t()} | :error
  def parse("stun" <> ":" <> host_port) do
    do_parse_stun(:stun, host_port)
  end

  def parse("stuns" <> ":" <> host_port) do
    do_parse_stun(:stuns, host_port)
  end

  def parse("turn" <> ":" <> host_port_transport) do
    do_parse_turn(:turn, host_port_transport)
  end

  def parse("turns" <> ":" <> host_port_transport) do
    do_parse_turn(:turns, host_port_transport)
  end

  def parse(_other), do: :error

  defp do_parse_stun(scheme, host_port) do
    default_port = if scheme == :stun, do: @default_udp_tcp_port, else: @default_tls_port
    default_transport = if scheme == :stuns, do: :tcp

    with {:ok, host, rest} <- parse_host(host_port),
         {:ok, port} <- parse_stun_port(rest) do
      {:ok,
       %__MODULE__{
         scheme: scheme,
         host: host,
         port: port || default_port,
         transport: default_transport
       }}
    else
      _ -> :error
    end
  end

  defp do_parse_turn(scheme, host_port_transport) do
    default_port = if scheme == :turn, do: @default_udp_tcp_port, else: @default_tls_port
    default_transport = if scheme == :turns, do: :tcp

    with {:ok, host, rest} <- parse_host(host_port_transport),
         {:ok, port, rest} <- parse_turn_port(rest),
         {:ok, transport} <- parse_transport(rest) do
      {:ok,
       %__MODULE__{
         scheme: scheme,
         host: host,
         port: port || default_port,
         transport: transport || default_transport
       }}
    end
  end

  defp parse_host(data) do
    case String.split(data, ":", parts: 2) do
      [host, rest] when host != "" ->
        {:ok, host, rest}

      [host] when host != "" ->
        case String.split(host, "?transport=") do
          [host, rest] when host != "" -> {:ok, host, "?transport=" <> rest}
          [host] -> {:ok, host, ""}
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp parse_stun_port(""), do: {:ok, nil}
  defp parse_stun_port(port), do: do_parse_port(port)

  defp parse_turn_port(""), do: {:ok, nil, ""}
  defp parse_turn_port("?transport=" <> rest), do: {:ok, nil, rest}

  defp parse_turn_port(data) do
    case String.split(data, "?transport=", parts: 2) do
      [port, rest] ->
        case do_parse_port(port) do
          {:ok, port} -> {:ok, port, rest}
          :error -> :error
        end

      [port] ->
        case do_parse_port(port) do
          {:ok, port} -> {:ok, port, ""}
          :error -> :error
        end
    end
  end

  defp do_parse_port(port) do
    case Integer.parse(port) do
      {port, ""} -> {:ok, port}
      _ -> :error
    end
  end

  defp parse_transport(""), do: {:ok, nil}
  defp parse_transport("udp"), do: {:ok, :udp}
  defp parse_transport("tcp"), do: {:ok, :tcp}
  defp parse_transport(_), do: :error
end
