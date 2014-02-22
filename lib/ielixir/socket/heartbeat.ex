defmodule IElixir.Socket.Heartbeat do
  require Lager
  alias IElixir.Socket.Common

  use GenServer.Behaviour

  def start_link(opts) do
    :gen_server.start_link({ :local, :heartbeat }, __MODULE__, opts, [])
  end

  ## Callbacks
  
  def init(opts) do
    sock = Common.make_socket(opts[:zmq_ctx], opts[:conn_info], "hb", :rep)
    { :ok, id } = :erlzmq.getsockopt(sock, :identity)
    { :ok, { sock, id } }
  end

  def terminate(_reason, { sock, _ }) do
    :erlzmq.close(sock)
  end

  def handle_info({ :zmq, _, data, [] }, state = { sock, id }) do
    :erlzmq.send(sock, data)
    { :noreply, state }
  end
  def handle_info(msg, state) do
    Lager.warn("Got unexpected message on hb process: #{inspect msg}")
    { :noreply, state}
  end
end
