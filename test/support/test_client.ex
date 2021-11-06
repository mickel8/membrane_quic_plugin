defmodule Membrane.QUIC.Support.TestClient do
  @moduledoc false

  use Membrane.Pipeline

  @impl true
  def handle_init(_opts) do
    children = %{
      file_src: %Membrane.File.Source{
        location: "./test_file"
      },
      quic_client: %Membrane.QUIC.Client{
        ip_address: {127, 0, 0, 1},
        port_number: 5000,
        alpn: ["example"],
        recv_datagram: true
      }
    }

    links = [link(:file_src) |> via_in(:dgram_input) |> to(:quic_client)]

    spec = %ParentSpec{
      children: children,
      links: links
    }

    {{:ok, spec: spec}, %{}}
  end
end
