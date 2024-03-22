defmodule ExSTUN.URITest do
  use ExUnit.Case, async: true

  alias ExSTUN.URI

  describe "parse/1" do
    test "with valid URI" do
      for {uri_string, expected_uri} <- [
            {
              "stun:stun.l.google.com:19302",
              %URI{scheme: :stun, host: "stun.l.google.com", port: 19_302, transport: nil}
            },
            {
              "stuns:stun.l.google.com:19302",
              %URI{scheme: :stuns, host: "stun.l.google.com", port: 19_302, transport: :tcp}
            },
            {
              "stun:stun.l.google.com",
              %URI{scheme: :stun, host: "stun.l.google.com", port: 3478, transport: nil}
            },
            {
              "stuns:stun.l.google.com",
              %URI{scheme: :stuns, host: "stun.l.google.com", port: 5349, transport: :tcp}
            },
            {
              "turn:example.org",
              %URI{scheme: :turn, host: "example.org", port: 3478, transport: nil}
            },
            {
              "turns:example.org",
              %URI{scheme: :turns, host: "example.org", port: 5349, transport: :tcp}
            },
            {
              "turn:example.org:8000",
              %URI{scheme: :turn, host: "example.org", port: 8000, transport: nil}
            },
            {
              "turn:example.org?transport=udp",
              %URI{scheme: :turn, host: "example.org", port: 3478, transport: :udp}
            },
            {
              "turn:example.org:1234?transport=udp",
              %URI{scheme: :turn, host: "example.org", port: 1234, transport: :udp}
            },
            {
              "turn:example.org?transport=tcp",
              %URI{scheme: :turn, host: "example.org", port: 3478, transport: :tcp}
            },
            {
              "turns:example.org?transport=tcp",
              %URI{scheme: :turns, host: "example.org", port: 5349, transport: :tcp}
            }
          ] do
        assert {:ok, expected_uri} == URI.parse(uri_string)
      end
    end

    test "with invalid URI" do
      for invalid_uri_string <- [
            "",
            "some random string",
            "stun:",
            "stun::",
            "stun::19302",
            "stun:?transport=",
            "abcd:stun.l.google.com:19302",
            "stun:stun.l.google.com:ab123",
            "stuns:stun.l.google.com:ab123",
            "stun:stun.l.google.com:19302?transport=udp",
            "stun:stun.l.google.com:19302?transport=",
            "turn:example.com:abc?transport=tcp",
            "turn:example.com:12345?transport=tls",
            "turn:example.com:abc"
          ] do
        assert :error == URI.parse(invalid_uri_string)
      end
    end
  end

  test "parse!/1" do
    assert %URI{} = URI.parse!("stun:stun.l.google.com")
    assert_raise RuntimeError, fn -> URI.parse!("invalid uri") end
  end
end
