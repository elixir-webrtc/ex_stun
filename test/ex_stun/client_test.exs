defmodule ExStun.ClientTest do
  use ExUnit.Case

  test "" do
    {:ok, pid} = ExStun.Client.start_link('stun.l.google.com', 19_302)

    m =
      ExStun.Message.new(%ExStun.Message.Type{
        class: :request,
        method: :binding
      })

    ExStun.Client.send(pid, m)
  end
end
