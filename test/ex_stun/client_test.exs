defmodule ExStun.ClientTest do
  use ExUnit.Case

  # alias ExStun.Message

  test "" do
    {:ok, pid} = ExStun.Client.start_link('stun.l.google.com', 19_302)

    m =
      ExStun.Message.new(%ExStun.Message.Type{
        class: :request,
        method: :binding
      })

    ExStun.Client.send(pid, m)
    Process.sleep(1000)
  end
end
