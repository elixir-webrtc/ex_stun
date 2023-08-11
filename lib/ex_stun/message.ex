defmodule ExSTUN.Message do
  @moduledoc """
  STUN Message

  ```ascii
        0                   1                   2                   3
      0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |0 0|     STUN Message Type     |         Message Length        |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |                         Magic Cookie                          |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |                                                               |
     |                     Transaction ID (96 bits)                  |
     |                                                               |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

                  Figure 2: Format of STUN Message Header
  ```
  """
  import Bitwise
  alias ExSTUN.Message.Attribute.Fingerprint
  alias ExSTUN.Message.Attribute.{MessageIntegrity, Realm, Username}
  alias ExSTUN.Message.{RawAttribute, Type}

  @magic_cookie 0x2112A442
  @fingerprint_xor_val 0x5354554E

  @typedoc """
  Possible `decode/1` error reasons.

  * `:not_enough_data` - provided binary is less than 20 bytes
  * `:malformed_header` - improper message header e.g. invalid cookie
  * `:unknown_method` - unknown message type method
  * `:data_after_finderprint` - fingerprint attribute is followed by other forbidden attributes
  * `:malformed_attr_padding` - one or more attributes are not followed by
  long enough padding or padding is not 0.
  """
  @type decode_error_t() ::
          :not_enough_data
          | :malformed_header
          | :malformed_type
          | :data_after_fingerprint
          | :malformed_attr_padding

  @type t() :: %__MODULE__{
          type: Type.t(),
          transaction_id: integer(),
          attributes: [RawAttribute.t()],
          len_to_int: integer(),
          raw: binary(),
          integrity: {boolean(), binary()},
          fingerprint: boolean()
        }

  @enforce_keys [:type, :transaction_id]
  defstruct @enforce_keys ++
              [
                attributes: [],
                len_to_int: 0,
                raw: <<>>,
                integrity: {false, <<>>},
                fingerprint: false
              ]

  @doc """
  Creates a new STUN message with a random transaction id.
  """
  @spec new(Type.t(), [struct()]) :: t()
  def new(%Type{} = type, attributes \\ []) do
    do_new(new_transaction_id(), type, attributes)
  end

  @doc """
  Creates a new STUN message.
  """
  @spec new(integer(), Type.t(), [struct()]) :: t()
  def new(transaction_id, %Type{} = type, attributes) when is_integer(transaction_id) do
    do_new(transaction_id, type, attributes)
  end

  defp do_new(tid, %Type{} = type, attributes) do
    msg = %__MODULE__{
      type: type,
      transaction_id: tid
    }

    raw_attributes = Enum.map(attributes, fn %attr_mod{} = attr -> attr_mod.to_raw(attr, msg) end)
    %__MODULE__{msg | attributes: raw_attributes}
  end

  @spec with_integrity(t(), binary()) :: t()
  def with_integrity(%__MODULE__{} = msg, key) do
    %__MODULE__{msg | integrity: {true, key}}
  end

  @spec with_fingerprint(t()) :: t()
  def with_fingerprint(%__MODULE__{} = msg) do
    %__MODULE__{msg | fingerprint: true}
  end

  @doc """
  Encodes a STUN message into a binary.
  """
  @spec encode(t()) :: binary()
  def encode(message) do
    type = Type.to_value(message.type)
    attributes = encode_attributes(message.attributes)
    length = byte_size(attributes)

    raw =
      <<0::1, 0::1, type::14, length::16, @magic_cookie::32, message.transaction_id::96,
        attributes::binary>>

    message = %__MODULE__{message | raw: raw}

    message =
      case message.integrity do
        {false, _} -> message
        {true, key} -> add_integrity(message, key)
      end

    message = if message.fingerprint, do: add_fingerprint(message), else: message
    message.raw
  end

  defp add_integrity(msg, key) do
    <<pre::binary-size(2), length::16, post::binary>> = msg.raw
    length = length + 20 + 4
    text = <<pre::binary, length::16, post::binary>>
    mac = :crypto.mac(:hmac, :sha, key, text)
    integrity = %MessageIntegrity{value: mac}
    raw_integrity = MessageIntegrity.to_raw(integrity, msg) |> RawAttribute.encode()
    %__MODULE__{msg | raw: <<text::binary, raw_integrity::binary>>}
  end

  defp add_fingerprint(msg) do
    <<pre::binary-size(2), length::16, post::binary>> = msg.raw
    length = length + 4 + 4
    text = <<pre::binary, length::16, post::binary>>
    crc = :erlang.crc32(text)
    fingerprint = %Fingerprint{value: bxor(crc, @fingerprint_xor_val)}
    raw_fingerprint = Fingerprint.to_raw(fingerprint, msg) |> RawAttribute.encode()
    %__MODULE__{msg | raw: <<text::binary, raw_fingerprint::binary>>}
  end

  @doc """
  Decodes a binary into a STUN message.
  """
  @spec decode(binary()) :: {:ok, t()} | {:error, decode_error_t()}
  def decode(raw)

  def decode(raw) when byte_size(raw) < 20 do
    {:error, :not_enough_data}
  end

  def decode(
        <<0::1, 0::1, type::14, _len::16, @magic_cookie::32, transaction_id::96,
          attributes::binary>> = msg
      ) do
    with {:ok, type} <- Type.from_value(type),
         {:ok, len_to_int, attributes} <- decode_attributes(attributes) do
      # len_to_int = length from beggining of the first attribute to end of message integrity
      {:ok,
       %__MODULE__{
         type: type,
         transaction_id: transaction_id,
         attributes: attributes,
         len_to_int: len_to_int,
         raw: msg
       }}
    end
  end

  def decode(_other), do: {:error, :malformed_header}

  @doc """
  Adds attribute to a message.
  """
  @spec add_attribute(t(), RawAttribute.t()) :: t()
  def add_attribute(message, %RawAttribute{} = attr) do
    %__MODULE__{message | attributes: message.attributes ++ [attr]}
  end

  @doc """
  Gets first attribute of given type from a message.

  `attr_mod` is a module implementing `ExSTUN.Message.Attribute` behaviour.
  Returns `nil` if there is no attribute of given type.
  """
  @spec get_attribute(t(), module()) :: {:ok, struct()} | {:error, atom()} | nil
  def get_attribute(message, attr_mod) do
    case Enum.find(message.attributes, &(&1.type == attr_mod.type())) do
      nil -> nil
      raw_attr -> attr_mod.from_raw(raw_attr, message)
    end
  end

  @doc """
  Gets all attributes of given type from the message.

  `attr_mod` is a module implementing `ExSTUN.Message.Attribute` behaviour.
  Returns `nil` if there is no attribute of given type.
  """
  @spec get_all_attributes(t(), module()) :: {:ok, [struct()]} | {:error, atom()} | nil
  def get_all_attributes(%__MODULE__{attributes: raw_attrs} = msg, attr_mod) do
    type = attr_mod.type()

    attrs =
      raw_attrs
      |> Enum.filter(&(&1.type == type))
      |> Enum.map(&attr_mod.from_raw(&1, msg))

    error = Enum.find(attrs, &match?({:error, _reason}, &1))

    cond do
      attrs == [] -> nil
      not is_nil(error) -> error
      true -> {:ok, Enum.map(attrs, fn {:ok, attr} -> attr end)}
    end
  end

  @doc """
  Authenticates a message long-term mechanism.

  `password` depends on the STUN authentication method and has to
  be provided from the outside.

  `key` is a key used for calculating MAC and can be used
  for adding message integrity in a response. See `with_integrity/2`.
  """
  @spec authenticate_lt(t(), binary()) ::
          {:ok, key :: binary()}
          | {:error,
             :no_message_integrity
             | :no_username
             | :no_realm
             | :no_matching_message_integrity
             | atom()}
  def authenticate_lt(msg, password) do
    with {:ok, %MessageIntegrity{} = msg_int} <- get_message_integrity(msg),
         {:ok, %Username{value: username}} <- get_username(msg),
         {:ok, %Realm{value: realm}} <- get_realm(msg) do
      key = username <> ":" <> realm <> ":" <> password
      key = :crypto.hash(:md5, key)

      # + 20 for STUN message header
      # - 24 for message integrity
      len = msg.len_to_int + 20 - 24
      <<msg_without_integrity::binary-size(len), _rest::binary>> = msg.raw
      <<pre_len::binary-size(2), _len::16, post_len::binary>> = msg_without_integrity
      msg_without_integrity = <<pre_len::binary, msg.len_to_int::16, post_len::binary>>

      mac = :crypto.mac(:hmac, :sha, key, msg_without_integrity)

      if mac == msg_int.value do
        {:ok, key}
      else
        {:error, :no_matching_message_integrity}
      end
    else
      {:error, _reason} = err -> err
    end
  end

  @doc """
  Authenticates a message using short-term mechanism.

  It is assumed that username attribute of this message is valid.

  `key` is a key used for calculating MAC and can be used
  for adding message integrity in a response. See `with_integrity/2`.
  """
  @spec authenticate_st(t(), binary()) ::
          {:ok, key :: binary()}
          | {:error, :no_message_integrity | :no_matching_message_integrity | atom()}
  def authenticate_st(msg, password) do
    case get_message_integrity(msg) do
      {:ok, %MessageIntegrity{} = msg_int} ->
        # + 20 for STUN message header
        # - 24 for message integrity
        len = msg.len_to_int + 20 - (20 + 4)
        <<msg_without_integrity::binary-size(len), _rest::binary>> = msg.raw
        <<pre_len::binary-size(2), _len::16, post_len::binary>> = msg_without_integrity
        msg_without_integrity = <<pre_len::binary, msg.len_to_int::16, post_len::binary>>

        # in short-term authentication key == password
        mac = :crypto.mac(:hmac, :sha, password, msg_without_integrity)

        if mac == msg_int.value do
          {:ok, password}
        else
          {:error, :no_matching_message_integrity}
        end

      {:error, _reason} = err ->
        err
    end
  end

  @spec check_fingerprint(t()) ::
          :ok | {:error, :no_fingerprint | :no_matching_fingerprint | atom()}
  def check_fingerprint(%__MODULE__{} = msg) do
    case get_attribute(msg, Fingerprint) do
      {:ok, %Fingerprint{} = fingerprint} ->
        # - 8 for Fingerprint Attribute length
        len = byte_size(msg.raw) - (4 + 4)
        <<msg_without_fingerprint::binary-size(len), _rest::binary>> = msg.raw
        crc = :erlang.crc32(msg_without_fingerprint)

        if bxor(crc, @fingerprint_xor_val) == fingerprint.value do
          :ok
        else
          {:error, :no_matching_fingerprint}
        end

      nil ->
        {:error, :no_fingerprint}

      {:error, _reason} = err ->
        err
    end
  end

  defp new_transaction_id() do
    <<t_id::12*8>> = :crypto.strong_rand_bytes(12)
    t_id
  end

  defp encode_attributes([]), do: <<>>

  defp encode_attributes(attributes) do
    for attribute <- attributes, into: <<>> do
      RawAttribute.encode(attribute)
    end
  end

  # acc - {len to int, int seen?, fingerprint seen?, attrs acc}
  defp decode_attributes(attributes, acc \\ {0, false, false, []})

  defp decode_attributes(<<>>, {len_to_int, _int_seen, true, attrs}), do: {:ok, len_to_int, attrs}

  defp decode_attributes(_raw_attrs, {_len_to_int, _int_seen, true, _attrs}),
    do: {:error, :data_after_fingerprint}

  defp decode_attributes(<<>>, {_len_to_int, false, false, attrs}),
    do: {:ok, 0, attrs}

  defp decode_attributes(<<>>, {len_to_int, true, false, attrs}),
    do: {:ok, len_to_int, attrs}

  defp decode_attributes(raw_attrs, {len_to_int, true, false, attrs}) do
    case decode_next_attr(raw_attrs) do
      {:ok, attr, _len, _is_int, true, rest} ->
        decode_attributes(rest, {len_to_int, true, true, attrs ++ [attr]})

      {:ok, _attr, _len, _is_int, false, _rest} ->
        {:ok, len_to_int, attrs}

      error ->
        error
    end
  end

  defp decode_attributes(raw_attrs, {len_to_int, false, false, attrs}) do
    with {:ok, attr, len, is_int, is_fingerprint, rest} <- decode_next_attr(raw_attrs) do
      case {is_int, is_fingerprint} do
        {true, false} ->
          decode_attributes(rest, {len_to_int + len, true, false, attrs ++ [attr]})

        {false, true} ->
          decode_attributes(rest, {0, false, true, attrs ++ [attr]})

        {false, false} ->
          decode_attributes(rest, {len_to_int + len, false, false, attrs ++ [attr]})
      end
    end
  end

  defp decode_next_attr(<<type::16, len::16, value::binary-size(len), rest::binary>>) do
    # attributes are alligned to 32 bits
    padding_len = rem(4 - rem(len, 4), 4)

    with {:ok, rest} <- strip_padding(rest, padding_len) do
      attr = %RawAttribute{type: type, value: value}
      # 0x0008 is message integrity
      # 0x8028 is fingerprint
      {:ok, attr, len + padding_len + 4, type == 0x0008, type == 0x8028, rest}
    end
  end

  defp decode_next_attr(_other), do: {:error, :malformed_attribute}

  defp strip_padding(data, padding_len) when byte_size(data) >= padding_len do
    <<_::padding_len*8, rest::binary>> = data
    {:ok, rest}
  end

  defp strip_padding(_data, _padding_len), do: {:error, :malformed_attr_padding}

  defp get_message_integrity(msg) do
    case get_attribute(msg, MessageIntegrity) do
      nil -> {:error, :no_message_integrity}
      other -> other
    end
  end

  defp get_username(msg) do
    case get_attribute(msg, Username) do
      nil -> {:error, :no_username}
      other -> other
    end
  end

  defp get_realm(msg) do
    case get_attribute(msg, Realm) do
      nil -> {:error, :no_realm}
      other -> other
    end
  end
end
