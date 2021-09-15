defmodule Membrane.QUIC.Sink do
  use Membrane.Sink

  require Membrane.Logger

  alias Membrane.Buffer

  def_options ip_address: [
                spec: :inet.ip_address(),
                description: "IP address to listen at"
              ],
              port_number: [
                spec: :inet.port_number(),
                description: "Port number to listen at"
              ],
              cert_path: [
                spec: String.t(),
                description: "Path to server certificate"
              ],
              key_path: [
                spec: String.t(),
                description: "Path to server key"
              ],
              alpn: [
                spec: [String.t()],
                description: "ALPN"
              ]

  def_input_pad :input,
    caps: :any,
    demand_unit: :buffers,
    availability: :on_request

  def_input_pad :dgram_input,
    caps: :any,
    demand_unit: :buffers

  @impl true
  def handle_init(%__MODULE__{
        ip_address: ip_address,
        port_number: port_number,
        cert_path: cert_path,
        key_path: key_path,
        alpn: alpn
      }) do
    {:ok, _} = Application.ensure_all_started(:quicer)

    options = [
      {:cert, cert_path},
      {:key, key_path},
      {:alpn, alpn},
      {:datagram_receive_enabled, 1}
    ]

    {:ok, l} = :quicer.listen(port_number, options)
    {:ok, conn} = :quicer.accept(l, [], 5000)
    {:ok, conn} = :quicer.handshake(conn)
    {:ok, stream} = :quicer.accept_stream(conn, [])
    {:ok, %{acc: <<>>, conn: conn, stream: stream}}
  end

  @impl true
  def handle_prepared_to_playing(context, state) do
    IO.inspect(context)
    {{:ok, demand: Pad.ref(:dgram_input)}, state}
  end

  @impl true
  def handle_write(:input, %Buffer{payload: payload}, _context, state) do
    {:ok, sent} = :quicer.send(state.stream, payload)
    {{:ok, demand: :input}, state}
  end

  @impl true
  def handle_write(:dgram_input, %Buffer{payload: payload}, _context, state) do
    {:ok, sent} = :quicer.send_dgram(state.conn, payload)
    {{:ok, demand: :dgram_input}, state}
  end

  @impl true
  def handle_other(msg, _ctx, state) do
    IO.inspect(msg)
    {:ok, state}
  end
end
