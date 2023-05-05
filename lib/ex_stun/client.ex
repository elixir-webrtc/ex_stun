defmodule ExSTUN.Client do
  @moduledoc """
  STUN Client
  """
  use GenServer

  alias ExSTUN.Message

  def start_link(address, port) do
    GenServer.start_link(__MODULE__, [address, port])
  end

  def send(pid, msg) do
    GenServer.cast(pid, {:send, msg})
  end

  @impl true
  def init([address, port]) do
    {:ok, socket} = :gen_udp.open(5555)
    :ok = :gen_udp.connect(socket, address, port)
    {:ok, %{socket: socket}}
  end

  @impl true
  def handle_cast({:send, msg}, state) do
    :ok = :gen_udp.send(state.socket, Message.encode(msg))
    {:noreply, state}
  end

  @impl true
  def handle_info({:udp, _socket, _ip, _port, data}, state) do
    IO.iodata_to_binary(data)
    |> ExSTUN.Message.decode()

    {:noreply, state}
  end
end
