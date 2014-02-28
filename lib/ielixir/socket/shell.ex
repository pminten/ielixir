defmodule IElixir.Socket.Shell do
  require Lager
  alias IElixir.Kernel
  alias IElixir.MsgBuffer
  alias IElixir.Socket.Common

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
      { :msg, msg } ->
        process(msg, sock)
        { :noreply, { sock, MsgBuffer.new } }
    end
  end
  def handle_info(msg, state) do
    Lager.warn("Got unexpected message on shell process: #{inspect msg}")
    { :noreply, state}
  end

  ## Internals

  defp process(msg = IElixir.Msg[msg_type: :kernel_info_request], sock) do
    { :ok, version } = Version.parse(System.version)
    content = [
      protocol_version: [3, 2],
      language_version: [version.major, version.minor, version.patch],
      language: "elixir"
    ]
    Common.respond(sock, msg, :kernel_info_reply, content)
  end
  defp process(msg = IElixir.Msg[msg_type: :execute_request], sock) do
    req = IElixir.Kernel.ExecuteRequest[
      code: msg.content["code"],
      silent: msg.content["silent"],
      store_history: msg.content["store_history"],
      user_variables: msg.content["user_variables"],
      user_expressions: msg.content["user_expressions"],
      allow_stdin: msg.content["allow_stdin"],
      msg_info: { msg.session, msg.username }
    ]
    content = case Kernel.execute_code(req) do
      { :ok, exec_count, payload, user_vars, user_exprs } -> [
          status: "ok", execution_count: exec_count,
          payload: payload, user_variables: user_vars,
          user_expressions: user_exprs
        ]
      { :error, exec_count, ename, evalue, traceback } -> [
          status: "error", execution_count: exec_count,
          ename: ename, evalue: evalue, traceback: traceback
        ]
      { :abort, exec_count } -> [
          status: "abort", execution_count: exec_count
        ]
    end
    Common.respond(sock, msg, :execute_reply, content)
  end
  defp process(msg, sock) do
    Lager.info("Got shell: #{inspect msg}")
    ## TODO
  end
end
