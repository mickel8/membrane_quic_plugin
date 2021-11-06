defmodule Membrane.QUIC.Client do
  use Membrane.Sink

  import Membrane.QUIC.Util

  require Membrane.Logger

  alias Membrane.Buffer

  def_options ip_address: [
                spec: :inet.ip_address(),
                description: "IP address to connect to"
              ],
              port_number: [
                spec: :inet.port_number(),
                description: "Port number to connect to"
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

  def_input_pad :input,
    caps: :any,
    demand_unit: :buffers,
    availability: :on_request

  def_input_pad :dgram_input,
    caps: :any,
    demand_unit: :buffers,
    availability: :on_request

  @impl true
  def handle_init(%__MODULE__{
        ip_address: ip_address,
        port_number: port_number,
        alpn: alpn,
        recv_datagram: recv_datagram
      }) do
    {:ok, _} = Application.ensure_all_started(:quicer)

    alpn = Enum.map(alpn, &String.to_charlist(&1))

    opts = [
      {:alpn, alpn},
      {:datagram_receive_enabled, to_int(recv_datagram)}
    ]

    {:ok, %{ip_address: ip_address, port_number: port_number, options: opts, streams: %{}}}
  end

  @impl true
  def handle_pad_added(Pad.ref(:input, id) = pad, _ctx, state) do
    Membrane.Logger.info("New pad: #{inspect(pad)} added. Creating new stream.")
    {:ok, stream} = :quicer.start_stream(state.conn, [])
    Membrane.Logger.info("Stream for pad: #{inspect(pad)} created")
    state = put_in(state, [:streams, id], stream)
    {{:ok, demand: pad}, state}
  end

  @impl true
  def handle_pad_added(Pad.ref(:dgram_input, _id) = pad, _ctx, state) do
    Membrane.Logger.info("New pad: #{inspect(pad)} added")
    {:ok, Map.put(state, :dgram_pad, pad)}
  end

  @impl true
  def handle_prepared_to_playing(context, state) do
    Membrane.Logger.info("Connecting")

    {:ok, conn} =
      :quicer.connect(
        '127.0.0.1',
        state.port_number,
        state.options,
        5000
      )

    demands = Enum.flat_map(state.streams, fn {id, _stm} -> [demand: Pad.ref(:input, id)] end)
    demands = demands ++ [demand: state.dgram_pad]
    {{:ok, demands}, Map.put(state, :conn, conn)}
  end

  @impl true
  def handle_write(Pad.ref(:input, id) = pad, %Buffer{payload: payload}, _context, state) do
    {:ok, _sent} = :quicer.send(Map.get(state.streams, id), payload)
    {{:ok, demand: pad}, state}
  end

  @impl true
  def handle_write(Pad.ref(:dgram_input, _id) = pad, %Buffer{payload: payload}, _context, state) do
    {:ok, _sent} = :quicer.send_dgram(state.conn, payload)
    {{:ok, demand: pad}, state}
  end

  @impl true
  def handle_other(msg, _ctx, state) do
    Membrane.Logger.warn("Got unexpected message #{inspect(msg)}")
    {:ok, state}
  end
end
