defmodule IElixir.Socket.IOPub do
  use GenServer.Behaviour

  alias IElixir.Socket.Common
  alias IElixir.MsgBuffer

  def start_link(opts) do
    :gen_server.start_link({ :local, :iopub }, __MODULE__, opts, [])
  end

  ## Callbacks
  
  def init(opts) do
    sock = Common.make_socket(opts[:zmq_ctx], opts[:conn_info], "iopub", :pub)
    { :ok, { sock, MsgBuffer.new } }
  end

  def terminate(_reason, { sock, _ } ) do
    :erlzmq.close(sock)
  end
end
