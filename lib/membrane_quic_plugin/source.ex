defmodule Membrane.QUIC.Source do
  use Membrane.Source

  alias Membrane.Buffer

  def_options ip_address: [
                spec: :inet.ip_address(),
                description: "IP address to connect to"
              ],
              port_number: [
                spec: :inet.port_number(),
                description: "Port number to connect to"
              ]

  def_output_pad :output,
    caps: :any

  def_output_pad :dgram_output,
    caps: :any

  @impl true
  def handle_init(%__MODULE__{ip_address: ip_address, port_number: port_number}) do
    {:ok, _} = Application.ensure_all_started(:quicer)

    {:ok, conn} =
      :quicer.connect(
        ip_address,
        port_number,
        [{:alpn, ['sample']}, {:datagram_receive_enabled, 1}],
        5000
      )

    {:ok, stream} = :quicer.start_stream(conn, [])
    {:ok, sent} = :quicer.send(stream, "ping")
    {:ok, %{conn: conn, stream: stream}}
  end

  @impl true
  def handle_demand(_, _, _, _, state) do
    {:ok, state}
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
  def handle_other(msg, _ctx, state) do
    IO.inspect(msg)
    {:ok, state}
  end
end
