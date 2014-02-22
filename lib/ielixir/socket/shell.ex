defmodule IElixir.Socket.Shell do
  require Lager
  alias IElixir.Socket.Common
  alias IElixir.MsgBuffer

  use GenServer.Behaviour

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
      { :buffer, new_buffer } ->
        { :noreply, { sock, new_buffer } }
      { :msg, rawmsg } ->
        process(rawmsg)
        { :noreply, { sock, MsgBuffer.new } }
    end
  end
  def handle_info(msg, state) do
    Lager.warn("Got unexpected message on shell process: #{inspect msg}")
    { :noreply, state}
  end

  ## Internals
  
  defp process(rawmsg) do
    Lager.info("Got shell: #{inspect rawmsg}")
    ## TODO
  end
end
