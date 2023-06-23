alias ExSTUN.Message
alias ExSTUN.Message.Attribute.{ErrorCode, Realm, Software, Username, XORMappedAddress}
alias ExSTUN.Message.RawAttribute
alias ExSTUN.Message.Type

# **IMPORTANT**
# 1. we don't use predefined structs in some benchmarks
# as we want to count in a time needed for struct creation
# 2. keep fixtures used in "decode" benchmarks the same
# as corresponding things in "encode" benchmarks
# 3. "decode" benchmarks don't decode RawAttribute into
# an actual attribute like Username, Software, etc. and
# therefore they are not fully symmetric with "encode" benchmarks

fix_lt_password = :crypto.mac(:hmac, :sha, "123456789", "someusername") |> :base64.encode()
fix_lt_key = "someusername" <> ":" <> "somerealm" <> ":" <> fix_lt_password
fix_lt_key = :crypto.hash(:md5, fix_lt_key)
fix_st_key = "somekey"

<<fix_t_id::12*8>> = :crypto.strong_rand_bytes(12)
fix_type = %Type{class: :success_response, method: :binding}
fix_type_value = Type.to_value(fix_type)
fix_m = Message.new(fix_t_id, fix_type, [])
fix_xor_addr = %XORMappedAddress{family: :ipv4, address: {127, 0, 0, 1}, port: 1234}
fix_raw_xor_addr = XORMappedAddress.to_raw(fix_xor_addr, fix_m)
fix_raw_error_code = ErrorCode.to_raw(%ErrorCode{code: 438, reason: "Stale Nonce"}, fix_m)
fix_raw_software = Software.to_raw(%Software{value: "software"}, fix_m)

{:ok, fix_full_message} =
  Message.new(fix_t_id, fix_type, [
    %Username{value: "someusername"},
    %Realm{value: "somerealm"},
    %XORMappedAddress{family: :ipv4, address: {127, 0, 0, 1}, port: 1234}
  ])
  |> Message.with_integrity(fix_st_key)
  |> Message.with_fingerprint()
  |> Message.encode()
  |> Message.decode()

{:ok, fix_full_lt_message} =
  Message.new(fix_t_id, fix_type, [
    %Username{value: "someusername"},
    %Realm{value: "somerealm"},
    %XORMappedAddress{family: :ipv4, address: {127, 0, 0, 1}, port: 1234}
  ])
  |> Message.with_integrity(fix_lt_key)
  |> Message.with_fingerprint()
  |> Message.encode()
  |> Message.decode()

fix_enc_full_message = Message.encode(fix_full_message)

fix_enc_binding_request =
  %Type{class: :request, method: :binding}
  |> Message.new()
  |> Message.encode()

fix_enc_binding_response =
  Message.new(fix_t_id, fix_type, [
    %XORMappedAddress{family: :ipv4, address: {127, 0, 0, 1}, port: 1234}
  ])
  |> Message.encode()

Benchee.run(
  %{
    "binding_request.encode" => fn ->
      %Type{class: :request, method: :binding}
      |> Message.new()
      |> Message.encode()
    end,
    "binding_request.decode" => fn ->
      {:ok, _} = Message.decode(fix_enc_binding_request)
    end,
    "binding_response.encode" => fn ->
      # we don't use fix_xor_mapped_address here
      # as we want to count in time needed for struct creation
      Message.new(fix_t_id, %Type{class: :success_response, method: :binding}, [
        %XORMappedAddress{family: :ipv4, address: {127, 0, 0, 1}, port: 1234}
      ])
      |> Message.encode()
    end,
    "binding_response.decode" => fn ->
      {:ok, _} = Message.decode(fix_enc_binding_response)
    end,
    "message_full.encode" => fn ->
      Message.new(fix_t_id, %Type{class: :success_response, method: :binding}, [
        %Username{value: "someusername"},
        %Realm{value: "somerealm"},
        %XORMappedAddress{family: :ipv4, address: {127, 0, 0, 1}, port: 1234}
      ])
      |> Message.with_integrity(fix_st_key)
      |> Message.with_fingerprint()
      |> Message.encode()
    end,
    "message_full.decode" => fn ->
      {:ok, _} = Message.decode(fix_enc_full_message)
    end,
    "message_full.authenticate_st" => fn ->
      {:ok, _} = Message.authenticate_st(fix_full_message, "someusername", fix_st_key)
    end,
    "message_full.authenticate_lt" => fn ->
      password = :crypto.mac(:hmac, :sha, "123456789", "someusername") |> :base64.encode()
      {:ok, _} = Message.authenticate_lt(fix_full_lt_message, password)
    end,
    "message_full.check_fingerprint" => fn ->
      true = Message.check_fingerprint(fix_full_message)
    end,
    "type.to_value" => fn ->
      Type.to_value(%Type{class: :success_response, method: :binding})
    end,
    "type.from_value" => fn ->
      {:ok, _} = Type.from_value(fix_type_value)
    end,
    "raw_attr.encode" => fn ->
      RawAttribute.encode(fix_raw_xor_addr)
    end,
    "error_code.to_raw" => fn ->
      ErrorCode.to_raw(%ErrorCode{code: 438, reason: "Stale Nonce"}, fix_m)
    end,
    "error_code.from_raw" => fn ->
      {:ok, _} = ErrorCode.from_raw(fix_raw_error_code, fix_m)
    end,
    "software.to_raw" => fn ->
      Software.to_raw(%Software{value: "software"}, fix_m)
    end,
    "software.from_raw" => fn ->
      {:ok, _} = Software.from_raw(fix_raw_software, fix_m)
    end,
    "xor_mapped_address.to_raw" => fn ->
      XORMappedAddress.to_raw(
        %XORMappedAddress{family: :ipv4, address: {127, 0, 0, 1}, port: 1234},
        fix_m
      )
    end,
    "xor_mapped_address.from_raw" => fn ->
      {:ok, _} = XORMappedAddress.from_raw(fix_raw_xor_addr, fix_m)
    end
  },
  memory_time: 2,
  reduction_time: 2,
  formatters: [{Benchee.Formatters.Console, extended_statistics: true, comparison: false}]
)
