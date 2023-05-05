defmodule ExSTUN.ClientTest do
  use ExUnit.Case

  test "" do
    {:ok, pid} = ExSTUN.Client.start_link('stun.l.google.com', 19_302)

    m =
      ExSTUN.Message.new(%ExSTUN.Message.Type{
        class: :request,
        method: :binding
      })

    ExSTUN.Client.send(pid, m)
  end
end
