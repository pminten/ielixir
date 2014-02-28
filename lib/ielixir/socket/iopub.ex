defmodule IElixir.Socket.IOPub do
  require Lager

  alias IElixir.Msg
  alias IElixir.MsgBuffer
  alias IElixir.MsgConv
  alias IElixir.Socket.Common

  use GenServer.Behaviour
  
  def start_link(opts) do
    :gen_server.start_link({ :local, :iopub }, __MODULE__, opts, [])
  end

  @doc """
  Print `text` on the IPython standard output stream through the IOPub
  mechanism.
  """
  def send_stdout(text, msg_info) do
    :gen_server.cast(:iopub, { :send, "stdout", text, msg_info })
  end

  @doc """
  Send a status (`:idle` or `:busy`) message.
  """
  def send_status(status) do
    :gen_server.cast(:iopub, { :send_status, status })
  end

  ## Callbacks
  
  def init(opts) do
    sock = Common.make_socket(opts[:zmq_ctx], opts[:conn_info], "iopub", :pub)
    # A bit hackish, but it should do for this one message.
    handle_cast({ :send_status, :starting }, sock)
    { :ok, sock }
  end

  def terminate(_reason, sock ) do
    :erlzmq.close(sock)
  end

  def handle_cast({ :send, stream, text, { session, username } }, sock) do
    msg = Msg[uuids: [stream],
              msg_id: :autogenerate,
              msg_type: :stream,
              session: session,
              username: username,
              content: [name: stream, data: text]]
    Common.send_all(sock, MsgConv.encode(msg))
    { :noreply, sock }
  end
  
  def handle_cast({ :send_status, status }, sock) do
    msg = Msg[uuids: ["status"],
              msg_id: :autogenerate,
              msg_type: :status,
              session: nil, 
              username: nil, 
              content: [execution_state: status]]
    Common.send_all(sock, MsgConv.encode(msg))
    { :noreply, sock }
  end
end
