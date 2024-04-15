# ExSTUN

[![Hex.pm](https://img.shields.io/hexpm/v/ex_stun.svg)](https://hex.pm/packages/ex_stun)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/ex_stun)
[![CI](https://img.shields.io/github/actions/workflow/status/elixir-webrtc/ex_stun/ci.yml?logo=github&label=CI)](https://github.com/elixir-webrtc/ex_stun/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/elixir-webrtc/ex_stun/branch/master/graph/badge.svg?token=7FJ64MDD0J)](https://codecov.io/gh/elixir-webrtc/ex_stun)

Implementation of the STUN protocol in Elixir - [RFC 8489](https://datatracker.ietf.org/doc/html/rfc8489)

## Installation
```elixir
def deps do
  [
    {:ex_stun, "~> 0.2.0"}
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
Elixir 1.16.0
Erlang 26.2.1
JIT enabled: true

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 2 s
reduction time: 2 s
parallel: 1
inputs: none specified
Estimated total run time: 3 min 29 s

Benchmarking binding_request.decode ...
Benchmarking binding_request.encode ...
Benchmarking binding_response.decode ...
Benchmarking binding_response.encode ...
Benchmarking error_code.from_raw ...
Benchmarking error_code.to_raw ...
Benchmarking message_full.authenticate (long-term) ...
Benchmarking message_full.authenticate (short-term) ...
Benchmarking message_full.check_fingerprint ...
Benchmarking message_full.decode ...
Benchmarking message_full.encode ...
Benchmarking new_transaction_id ...
Benchmarking raw_attr.encode ...
Benchmarking software.from_raw ...
Benchmarking software.to_raw ...
Benchmarking type.from_value ...
Benchmarking type.to_value ...
Benchmarking xor_mapped_address.from_raw ...
Benchmarking xor_mapped_address.to_raw ...
Calculating statistics...
Formatting results...

Name                                             ips        average  deviation         median         99th %
error_code.to_raw                            36.93 M       27.08 ns  ±7981.76%          26 ns          39 ns
software.to_raw                              17.55 M       56.99 ns ±58293.86%          32 ns          47 ns
type.to_value                                13.21 M       75.68 ns ±53851.08%          47 ns          60 ns
software.from_raw                            12.70 M       78.76 ns ±48756.65%          39 ns          53 ns
raw_attr.encode                               6.76 M      147.84 ns ±35284.68%          84 ns          99 ns
error_code.from_raw                           6.68 M      149.72 ns ±31869.06%          68 ns         308 ns
xor_mapped_address.from_raw                   6.53 M      153.04 ns ±24195.15%          90 ns         317 ns
type.from_value                               5.93 M      168.77 ns ±29536.32%          89 ns         169 ns
xor_mapped_address.to_raw                     4.83 M      206.94 ns ±18672.29%         154 ns         204 ns
binding_request.decode                        3.88 M      257.52 ns ±18794.26%         164 ns         405 ns
binding_response.decode                       2.58 M      387.01 ns ±12289.08%         258 ns         598 ns
message_full.check_fingerprint                1.96 M      509.65 ns  ±8520.92%         410 ns         631 ns
binding_response.encode                       1.75 M      572.69 ns  ±7262.63%         463 ns         800 ns
message_full.decode                           1.18 M      848.38 ns  ±3970.03%         719 ns        1054 ns
new_transaction_id                            0.98 M     1024.22 ns  ±1116.74%        1010 ns        1049 ns
binding_request.encode                        0.76 M     1321.81 ns  ±1477.79%        1272 ns        1540 ns
message_full.authenticate (short-term)        0.35 M     2845.65 ns   ±876.74%        2516 ns        3779 ns
message_full.authenticate (long-term)         0.26 M     3873.42 ns   ±532.72%        3423 ns        5354 ns
message_full.encode                           0.21 M     4870.66 ns   ±604.07%        4115 ns        8119 ns

Extended statistics: 

Name                                           minimum        maximum    sample size                     mode
error_code.to_raw                                23 ns     7959548 ns        13.57 M                    26 ns
software.to_raw                                  28 ns   113335333 ns        12.84 M                    32 ns
type.to_value                                    42 ns   103387309 ns        12.87 M                    46 ns
software.from_raw                                35 ns   115844653 ns        12.51 M                    39 ns
raw_attr.encode                                  79 ns   112984566 ns        11.40 M                    84 ns
error_code.from_raw                              63 ns   112746828 ns        11.17 M                    68 ns
xor_mapped_address.from_raw                      84 ns    83446950 ns        10.82 M                    90 ns
type.from_value                                  81 ns    99367969 ns        10.89 M                    89 ns
xor_mapped_address.to_raw                       146 ns    80528411 ns         9.65 M                   153 ns
binding_request.decode                          153 ns    94202921 ns         9.29 M                   162 ns
binding_response.decode                         240 ns    68201852 ns         7.57 M                   250 ns
message_full.check_fingerprint                  390 ns    59291887 ns         6.27 M                   409 ns
binding_response.encode                         448 ns    59683037 ns         5.73 M                   463 ns
message_full.decode                             681 ns    44644869 ns         4.46 M                   704 ns
new_transaction_id                              975 ns    20779566 ns         3.65 M                  1013 ns
binding_request.encode                         1225 ns    23295785 ns         2.94 M                  1271 ns
message_full.authenticate (short-term)         2401 ns    14778234 ns         1.58 M                  2500 ns
message_full.authenticate (long-term)          3243 ns     9581577 ns         1.18 M                  3368 ns
message_full.encode                            3880 ns    19112426 ns       948.71 K                  4085 ns

Memory usage statistics:

Name                                      Memory usage
error_code.to_raw                                  0 B
software.to_raw                                   48 B - ∞ x memory usage +48 B
type.to_value                                      0 B - 1.00x memory usage +0 B
software.from_raw                                 64 B - ∞ x memory usage +64 B
raw_attr.encode                                   32 B - ∞ x memory usage +32 B
error_code.from_raw                              144 B - ∞ x memory usage +144 B
xor_mapped_address.from_raw                      264 B - ∞ x memory usage +264 B
type.from_value                                  384 B - ∞ x memory usage +384 B
xor_mapped_address.to_raw                        232 B - ∞ x memory usage +232 B
binding_request.decode                           648 B - ∞ x memory usage +648 B
binding_response.decode                         1024 B - ∞ x memory usage +1024 B
message_full.check_fingerprint                   232 B - ∞ x memory usage +232 B
binding_response.encode                          688 B - ∞ x memory usage +688 B
message_full.decode                             2928 B - ∞ x memory usage +2928 B
new_transaction_id                                72 B - ∞ x memory usage +72 B
binding_request.encode                           360 B - ∞ x memory usage +360 B
message_full.authenticate (short-term)           664 B - ∞ x memory usage +664 B
message_full.authenticate (long-term)            808 B - ∞ x memory usage +808 B
message_full.encode                             2344 B - ∞ x memory usage +2344 B

**All measurements for memory usage were the same**

Reduction count statistics:

Name                                   Reduction count
error_code.to_raw                                    0
software.to_raw                                      2 - ∞ x reduction count +2
type.to_value                                        5 - ∞ x reduction count +5
software.from_raw                                    3 - ∞ x reduction count +3
raw_attr.encode                                      1 - ∞ x reduction count +1
error_code.from_raw                                  3 - ∞ x reduction count +3
xor_mapped_address.from_raw                         13 - ∞ x reduction count +13
type.from_value                                      6 - ∞ x reduction count +6
xor_mapped_address.to_raw                           10 - ∞ x reduction count +10
binding_request.decode                              11 - ∞ x reduction count +11
binding_response.decode                             17 - ∞ x reduction count +17
message_full.check_fingerprint                      43 - ∞ x reduction count +43
binding_response.encode                             40 - ∞ x reduction count +40
message_full.decode                                 53 - ∞ x reduction count +53
new_transaction_id                                   3 - ∞ x reduction count +3
binding_request.encode                              22 - ∞ x reduction count +22
message_full.authenticate (short-term)              49 - ∞ x reduction count +49
message_full.authenticate (long-term)               84 - ∞ x reduction count +84
message_full.encode                                 99 - ∞ x reduction count +99

**All measurements for reduction count were the same**
```