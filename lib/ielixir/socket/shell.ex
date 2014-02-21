defmodule IElixir.Socket.Shell do
  use GenServer.Behaviour

  alias IElixir.Socket.Common
  alias IElixir.MsgBuffer

  def start_link(opts) do
    :gen_server.start_link({ :local, :shell }, __MODULE__, opts, [])
  end

  ## Callbacks
  
  def init(opts) do
    sock = Common.make_socket(opts[:zmq_ctx], opts[:conn_info], "shell", :router)
    { :ok, { sock, MsgBuffer.new } }
  end

  def terminate(_reason, { sock, _ } ) do
    :erlzmq.close(sock)
  end

  def handle_info({ :zmq, _, msg, flags }, { sock, buffer }) do
    case MsgBuffer.store_part(msg, flags, buffer) do
      { :buffer, new_buffer } -> { :ok, { sock, new_buffer } }
      { :msg, rawmsg } ->
        process(rawmsg)
        { :ok, { sock, MsgBuffer.new } }
    end
  end

  ## Internals
  
  defp process(rawmsg) do
    ## TODO
  end
end
