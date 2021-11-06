defmodule Membrane.QUIC.Support.TestServer do
  @moduledoc false

  use Membrane.Pipeline

  @impl true
  def handle_init(_opts) do
    children = %{
      quic_server: %Membrane.QUIC.Server{
        ip_address: {127, 0, 0, 1},
        port_number: 5000,
        cert_path: "./cert.pem",
        key_path: "./key.pem",
        alpn: ["example"],
        recv_datagram: true
      },
      file_sink: %Membrane.File.Sink{
        location: "./recv_file"
      }
    }

    links = [link(:quic_server) |> via_out(:dgram_output) |> to(:file_sink)]

    spec = %ParentSpec{
      children: children,
      links: links
    }

    {{:ok, spec: spec}, %{}}
  end
end
