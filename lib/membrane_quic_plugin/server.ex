defmodule Membrane.QUIC.Server do
  use Membrane.Source

  import Membrane.QUIC.Util

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
              ],
              recv_datagram: [
                spec: boolean(),
                default: true,
                description: "Whether to receive DATAGRAM frames or not"
              ]

  def_output_pad :output,
    availability: :on_request,
    caps: :any

  def_output_pad :dgram_output,
    caps: :any

  @impl true
  def handle_init(%__MODULE__{
        port_number: port_number,
        cert_path: cert_path,
        key_path: key_path,
        recv_datagram: recv_datagram,
        alpn: alpn
      }) do
    {:ok, _} = Application.ensure_all_started(:quicer)

    alpn = Enum.map(alpn, &String.to_charlist(&1))

    options = [
      {:cert, String.to_charlist(cert_path)},
      {:key, String.to_charlist(key_path)},
      {:alpn, alpn},
      {:datagram_receive_enabled, to_int(recv_datagram)}
    ]

    {:ok, %{port_number: port_number, options: options}}
  end

  @impl true
  def handle_demand(_pad, _size, _units, _ctx, state) do
    {:ok, state}
  end

  @impl true
  def handle_prepared_to_playing(_ctx, state) do
    {:ok, l} = :quicer.listen(state.port_number, state.options)
    Membrane.Logger.info("Listening to a connection")
    {:ok, conn} = :quicer.accept(l, [], 5000)
    {:ok, conn} = :quicer.handshake(conn)
    Membrane.Logger.info("Handshake successful")
    #    {:ok, stream} = :quicer.accept_stream(conn, [])
    #    Membrane.Logger.debug("Stream accepted")
    {:ok, Map.merge(state, %{conn: conn, stream: nil})}
  end

  @impl true
  def handle_other({:quic, payload, stream, _, _, _}, _ctx, state) do
    actions = [buffer: {:output, %Buffer{payload: payload, metadata: %{}}}]
    {{:ok, actions}, %{state | stream: stream}}
  end

  @impl true
  def handle_other({:quic, :dgram, payload}, _ctx, state) do
    actions = [buffer: {:dgram_output, %Buffer{payload: payload, metadata: %{}}}]
    {{:ok, actions}, state}
  end

  @impl true
  def handle_other({:get_stats, from}, _ctx, state) do
    stats =
      :quicer.getstat(state.conn, [
        :recv_cnt,
        :recv_max,
        :recv_avg,
        :recv_oct,
        :recv_dvi,
        :send_cnt,
        :send_max,
        :send_avg,
        :send_oct,
        :send_pend
      ])

    send(from, stats)
    {:ok, state}
  end

  @impl true
  def handle_other(msg, _ctx, state) do
    Membrane.Logger.warn("Got unexpected message: #{inspect(msg)}")
    {:ok, state}
  end
end
