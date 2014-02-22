defmodule IElixir.Socket.Stdin do
  require Lager
  alias IElixir.Socket.Common
  alias IElixir.MsgBuffer
  
  use GenServer.Behaviour

  def start_link(opts) do
    :gen_server.start_link({ :local, :stdin }, __MODULE__, opts, [])
  end

  ## Callbacks
  
  def init(opts) do
    sock = Common.make_socket(opts[:zmq_ctx], opts[:conn_info], "stdin", :router)
    { :ok, { sock, MsgBuffer.new } }
  end

  def terminate(_reason, { sock, _ } ) do
    :erlzmq.close(sock)
  end

  def handle_info({ :zmq, _, msg, flags }, { sock, buffer }) do
    case MsgBuffer.store_part(msg, flags, buffer) do
      { :buffer, new_buffer } ->
        { :noreply, { sock, new_buffer } }
      { :msg, msg } ->
        process(msg)
        { :noreply, { sock, MsgBuffer.new } }
    end
  end
  def handle_info(msg, state) do
    Lager.warn("Got unexpected message on stdin process: #{inspect msg}")
    { :noreply, state}
  end

  ## Internals
  
  defp process(msg) do
    ## TODO
  end
end
