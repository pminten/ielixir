defmodule IElixir.Socket.Heartbeat do
  use GenServer.Behaviour

  alias IElixir.Socket.Common
  
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

  def handle_info({ :zmq, _, ts, [] }, state = { sock, id }) do
    Common.send_all(sock, [ id, ts ])
    { :ok, state }
  end
end
