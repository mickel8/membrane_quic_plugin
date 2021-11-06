defmodule Membrane.QUIC.IntegrationTest do
  use ExUnit.Case, async: true

  alias Membrane.Testing

  @file_path "./recv_file"

  test "QUIC server receives data from QUIC client" do
    {:ok, rx_pid} =
      Testing.Pipeline.start_link(%Testing.Pipeline.Options{
        module: Membrane.QUIC.Support.TestServer
      })

    {:ok, tx_pid} =
      Testing.Pipeline.start_link(%Testing.Pipeline.Options{
        module: Membrane.QUIC.Support.TestClient
      })

    :ok = Testing.Pipeline.play(rx_pid)

    :timer.sleep(1000)

    :ok = Testing.Pipeline.play(tx_pid)

    :timer.sleep(1000)

    assert File.exists?(@file_path)
    %{size: size} = File.stat!(@file_path)
    assert size > 700

    Membrane.Pipeline.stop_and_terminate(rx_pid, blocking?: true)
    Membrane.Pipeline.stop_and_terminate(tx_pid, blocking?: true)
  end
end
