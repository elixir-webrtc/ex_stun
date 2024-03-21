alias ExSTUN.Message
alias ExSTUN.Message.Attribute.{ErrorCode, Realm, Software, Username, XORMappedAddress}
alias ExSTUN.Message.RawAttribute
alias ExSTUN.Message.Type

# **IMPORTANT**
# 1. we don't use predefined structs in some benchmarks
# as we want to count in a time needed for struct creation
# e.g software_to_raw, error_to_raw, etc.
# 2. keep fixtures used in "decode" benchmarks the same
# as corresponding things in "encode" benchmarks
# 3. "decode" benchmarks don't decode RawAttribute into
# an actual attribute like Username, Software, etc. and
# therefore they are not fully symmetric with "encode" benchmarks

fix_lt_password = :crypto.mac(:hmac, :sha, "123456789", "someusername") |> :base64.encode()
fix_lt_key = Message.lt_key("someusername", fix_lt_password, "somerealm")
fix_st_key = "somekey"

<<fix_t_id::12*8>> = :crypto.strong_rand_bytes(12)
fix_type = %Type{class: :success_response, method: :binding}
fix_type_value = Type.to_value(fix_type)
fix_m = Message.new(fix_t_id, fix_type, [])

full_msg_enc = fn key ->
  Message.new(fix_t_id, fix_type, [
    %Username{value: "someusername"},
    %Realm{value: "somerealm"},
    %XORMappedAddress{address: {127, 0, 0, 1}, port: 1234}
  ])
  |> Message.with_integrity(key)
  |> Message.with_fingerprint()
  |> Message.encode()
end

binding_request_enc = fn ->
  %Type{class: :request, method: :binding}
  |> Message.new()
  |> Message.encode()
end

binding_response_enc = fn ->
  Message.new(fix_t_id, fix_type, [%XORMappedAddress{address: {127, 0, 0, 1}, port: 1234}])
  |> Message.encode()
end

xor_addr_to_raw = fn ->
  XORMappedAddress.to_raw(%XORMappedAddress{address: {127, 0, 0, 1}, port: 1234}, fix_m)
end

software_to_raw = fn ->
  Software.to_raw(%Software{value: "software"}, fix_m)
end

error_code_to_raw = fn ->
  ErrorCode.to_raw(%ErrorCode{code: 438, reason: "Stale Nonce"}, fix_m)
end

{:ok, fix_full_message} = full_msg_enc.(fix_st_key) |> Message.decode()
{:ok, fix_full_lt_message} = full_msg_enc.(fix_lt_key) |> Message.decode()
fix_enc_full_message = full_msg_enc.(fix_st_key)

fix_enc_binding_request = binding_request_enc.()
fix_enc_binding_response = binding_response_enc.()

fix_raw_software = software_to_raw.()
fix_raw_error_code = error_code_to_raw.()
fix_raw_xor_addr = xor_addr_to_raw.()

Benchee.run(
  %{
    "new_transaction_id" => fn -> <<t_id::12*8>> = :crypto.strong_rand_bytes(12) end,
    "binding_request.encode" => fn -> binding_request_enc.() end,
    "binding_request.decode" => fn -> {:ok, _} = Message.decode(fix_enc_binding_request) end,
    "binding_response.encode" => fn -> binding_response_enc.() end,
    "binding_response.decode" => fn -> {:ok, _} = Message.decode(fix_enc_binding_response) end,
    "message_full.encode" => fn -> full_msg_enc.(fix_st_key) end,
    "message_full.decode" => fn -> {:ok, _} = Message.decode(fix_enc_full_message) end,
    "message_full.authenticate (short-term)" => fn ->
      # check if username is correct and authenticate
      {:ok, username} = Message.get_attribute(fix_full_message, Username)
      username.value == "someusername"
      :ok = Message.authenticate(fix_full_message, fix_st_key)
    end,
    "message_full.authenticate (long-term)" => fn ->
      {:ok, username} = Message.get_attribute(fix_full_lt_message, Username)
      {:ok, realm} = Message.get_attribute(fix_full_lt_message, Realm)
      key = Message.lt_key(username.value, fix_lt_password, realm.value)
      :ok = Message.authenticate(fix_full_lt_message, key)
    end,
    "message_full.check_fingerprint" => fn ->
      :ok = Message.check_fingerprint(fix_full_message)
    end,
    "type.to_value" => fn ->
      Type.to_value(%Type{class: :success_response, method: :binding})
    end,
    "type.from_value" => fn -> {:ok, _} = Type.from_value(fix_type_value) end,
    "raw_attr.encode" => fn -> RawAttribute.encode(fix_raw_xor_addr) end,
    "error_code.to_raw" => fn -> nil end,
    "error_code.from_raw" => fn -> {:ok, _} = ErrorCode.from_raw(fix_raw_error_code, fix_m) end,
    "software.to_raw" => fn -> software_to_raw.() end,
    "software.from_raw" => fn -> {:ok, _} = Software.from_raw(fix_raw_software, fix_m) end,
    "xor_mapped_address.to_raw" => fn -> xor_addr_to_raw.() end,
    "xor_mapped_address.from_raw" => fn ->
      {:ok, _} = XORMappedAddress.from_raw(fix_raw_xor_addr, fix_m)
    end
  },
  memory_time: 2,
  reduction_time: 2,
  formatters: [{Benchee.Formatters.Console, extended_statistics: true, comparison: false}]
)
