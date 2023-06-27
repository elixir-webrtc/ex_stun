# ExSTUN

[![codecov](https://codecov.io/gh/elixir-webrtc/ex_stun/branch/master/graph/badge.svg?token=7FJ64MDD0J)](https://codecov.io/gh/elixir-webrtc/ex_stun)

Implementation of STUN protocol - [RFC 8489](https://datatracker.ietf.org/doc/html/rfc8489)

## Installation
```elixir
def deps do
  [
    {:ex_stun, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
alias ExSTUN.Message
alias ExSTUN.Message.Type
alias ExSTUN.Message.Attribute.XORMappedAddress

{:ok, socket} = :gen_udp.open(0, [{:active, false}, :binary])

req = 
  %Type{class: :request, method: :binding}
  |> Message.new() 
  |> Message.encode()

:ok = :gen_udp.send(socket, 'stun.l.google.com', 19302, req)
{:ok, {_, _, resp}} = :gen_udp.recv(socket, 0)

{:ok, msg} = Message.decode(resp)
Message.get_attribute(msg, XORMappedAddress)
```

## Benchmarks

```
Operating System: Linux
CPU Information: Intel(R) Core(TM) i5-9600K CPU @ 3.70GHz
Number of Available Cores: 6
Available memory: 15.55 GB
Elixir 1.14.2
Erlang 25.1

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 2 s
reduction time: 2 s
parallel: 1
inputs: none specified
Estimated total run time: 3.30 min

Benchmarking binding_request.decode ...
Benchmarking binding_request.encode ...
Benchmarking binding_response.decode ...
Benchmarking binding_response.encode ...
Benchmarking error_code.from_raw ...
Benchmarking error_code.to_raw ...
Benchmarking message_full.authenticate_lt ...
Benchmarking message_full.authenticate_st ...
Benchmarking message_full.check_fingerprint ...
Benchmarking message_full.decode ...
Benchmarking message_full.encode ...
Benchmarking raw_attr.encode ...
Benchmarking software.from_raw ...
Benchmarking software.to_raw ...
Benchmarking type.from_value ...
Benchmarking type.to_value ...
Benchmarking xor_mapped_address.from_raw ...
Benchmarking xor_mapped_address.to_raw ...

Name                                     ips        average  deviation         median         99th %
type.to_value                        10.36 M       96.49 ns ±21841.52%          82 ns          85 ns
software.to_raw                       9.27 M      107.92 ns ±18500.54%          88 ns         127 ns
software.from_raw                     9.09 M      109.98 ns ±10619.86%          93 ns         146 ns
raw_attr.encode                       5.52 M      181.24 ns ±20597.53%         134 ns         151 ns
error_code.to_raw                     5.33 M      187.68 ns ±18721.74%         131 ns         173 ns
error_code.from_raw                   5.24 M      190.85 ns ±21761.54%         133 ns         188 ns
xor_mapped_address.from_raw           4.26 M      234.63 ns ±20120.48%         139 ns         404 ns
type.from_value                       3.52 M      284.43 ns ±16103.68%         203 ns         345 ns
xor_mapped_address.to_raw             3.32 M      301.39 ns ±15498.33%         224 ns         280 ns
binding_request.decode                2.55 M      391.79 ns  ±8498.86%         312 ns         562 ns
message_full.check_fingerprint        2.44 M      410.01 ns  ±8473.68%         321 ns         568 ns
binding_response.decode               1.91 M      522.90 ns  ±7523.76%         419 ns         743 ns
binding_response.encode               1.51 M      661.60 ns  ±4805.20%         536 ns         830 ns
message_full.decode                   0.93 M     1069.54 ns  ±2911.76%         943 ns        1285 ns
binding_request.encode                0.74 M     1353.22 ns  ±1471.32%        1268 ns        1510 ns
message_full.authenticate_st          0.38 M     2624.01 ns   ±938.16%        2325 ns        3347 ns
message_full.encode                   0.22 M     4590.41 ns   ±382.62%        3880 ns        6658 ns
message_full.authenticate_lt         0.182 M     5505.80 ns   ±331.43%        4992 ns     7209.08 ns

Extended statistics: 

Name                                   minimum        maximum    sample size                     mode
type.to_value                            77 ns    53061243 ns        10.88 M                    82 ns
software.to_raw                          82 ns    53144998 ns        10.48 M                    86 ns
software.from_raw                        88 ns    25514683 ns        10.09 M                    92 ns
raw_attr.encode                         128 ns    74961546 ns         9.52 M                   134 ns
error_code.to_raw                       121 ns    74838686 ns         9.54 M                   130 ns
error_code.from_raw                     123 ns    71867196 ns         9.47 M                   133 ns
xor_mapped_address.from_raw             131 ns    74689484 ns         9.00 M                   138 ns
type.from_value                         191 ns    70955773 ns         8.15 M                   201 ns
xor_mapped_address.to_raw               211 ns    71053082 ns         7.87 M                   224 ns
binding_request.decode                  296 ns    51298433 ns         6.98 M                   310 ns
message_full.check_fingerprint          308 ns    59012006 ns         6.64 M                   318 ns
binding_response.decode                 394 ns    48415319 ns         5.96 M                   414 ns
binding_response.encode                 519 ns    36950899 ns         5.04 M                   535 ns
message_full.decode                     860 ns    29238503 ns         3.61 M                   927 ns
binding_request.encode                 1227 ns    19876704 ns         2.95 M                  1267 ns
message_full.authenticate_st           2236 ns    14685021 ns         1.68 M                  2309 ns
message_full.encode                    3688 ns     7095523 ns         1.00 M                  3848 ns
message_full.authenticate_lt           4837 ns     6284531 ns       844.69 K         4973 ns, 4968 ns

Memory usage statistics:

Name                              Memory usage
type.to_value                              0 B
software.to_raw                           80 B - ∞ x memory usage +80 B
software.from_raw                         88 B - ∞ x memory usage +88 B
raw_attr.encode                           32 B - ∞ x memory usage +32 B
error_code.to_raw                        112 B - ∞ x memory usage +112 B
error_code.from_raw                      176 B - ∞ x memory usage +176 B
xor_mapped_address.from_raw              312 B - ∞ x memory usage +312 B
type.from_value                          416 B - ∞ x memory usage +416 B
xor_mapped_address.to_raw                264 B - ∞ x memory usage +264 B
binding_request.decode                   752 B - ∞ x memory usage +752 B
message_full.check_fingerprint           256 B - ∞ x memory usage +256 B
binding_response.decode                 1160 B - ∞ x memory usage +1160 B
binding_response.encode                  832 B - ∞ x memory usage +832 B
message_full.decode                     3192 B - ∞ x memory usage +3192 B
binding_request.encode                   432 B - ∞ x memory usage +432 B
message_full.authenticate_st             736 B - ∞ x memory usage +736 B
message_full.encode                     2664 B - ∞ x memory usage +2664 B
message_full.authenticate_lt            1448 B - ∞ x memory usage +1448 B

**All measurements for memory usage were the same**

Reduction count statistics:

Name                           Reduction count
type.to_value                                5
software.to_raw                              1 - 0.20x reduction count -4
software.from_raw                            3 - 0.60x reduction count -2
raw_attr.encode                              1 - 0.20x reduction count -4
error_code.to_raw                            3 - 0.60x reduction count -2
error_code.from_raw                          3 - 0.60x reduction count -2
xor_mapped_address.from_raw                 11 - 2.20x reduction count +6
type.from_value                              6 - 1.20x reduction count +1
xor_mapped_address.to_raw                    7 - 1.40x reduction count +2
binding_request.decode                      11 - 2.20x reduction count +6
message_full.check_fingerprint              43 - 8.60x reduction count +38
binding_response.decode                     17 - 3.40x reduction count +12
binding_response.encode                     37 - 7.40x reduction count +32
message_full.decode                         56 - 11.20x reduction count +51
binding_request.encode                      21 - 4.20x reduction count +16
message_full.authenticate_st                60 - 12.00x reduction count +55
message_full.encode                        108 - 21.60x reduction count +103
message_full.authenticate_lt               113 - 22.60x reduction count +108

**All measurements for reduction count were the same**
```