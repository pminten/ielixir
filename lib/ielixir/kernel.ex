defmodule IElixir.Kernel do
  @moduledoc """
  The kernel process proper.
  """
  alias IElixir.Socket.IOPub

  use GenServer.Behaviour

  defrecord ExecuteRequest, code: nil, silent: false, store_history: true,
                            user_variables: [], user_expressions: [],
                            allow_stdin: true, msg_info: { nil, nil } do
    @moduledoc """
    Helper record to pass the execute_request fields to the kernel.

    The `msg_info` field contains session and username from the original
    message, which is needed for things like sending an IOPub message.
    """
  end

  defrecord State, exec_count: 1, binding: nil, env: nil, scope: nil do
    @moduledoc """
    State of the kernel process.
    """
  end

  def start_link(opts) do
    :gen_server.start_link({ :local, :kernel }, __MODULE__, opts, [])
  end

  @doc """
  Handle an execute_request.

  Returns one of:
  * `{ :ok, exec_count, payload, user_vars, user_exprs }`
  * `{ :error, exec_count, ename, evalue, traceback }`
  * `{ :abort, exec_count }`
  """
  def execute_code(req) do
    :gen_server.call(:kernel, { :execute_code, req })
  end

  ## Callbacks
 
  def init(_) do
    { _, _, env, scope } = :elixir.eval('require IElixir.Helpers', [],
                                        :elixir.env_for_eval(file: "ipython"))
    { :ok, State[exec_count: 0, binding: [], env: env, scope: scope] }
  end

  def handle_call({ :execute_code, req }, _from, state) do
    { rep_type, rep_fields, new_state } = eval(req, state)
    { :reply, list_to_tuple([rep_type, new_state.exec_count | tuple_to_list(rep_fields)]),
              new_state } 
  end

  ## Internals
  
  defp eval(req, state = State[]) do
    IOPub.send_status(:busy)
  #    try do
      result = do_eval(req, state)
      #    catch
      #      kind, error ->
      #        # TODO: Tracebacks that ipython understands
      #        { :error, { inspect(kind), inspect(error), [] }, state }
      #    end
    IOPub.send_status(:idle)
    result
  end

  defp do_eval(req = ExecuteRequest[], state = State[]) do
    case Code.string_to_quoted(req.code, [line: state.exec_count, file: "ipython"]) do
      { :ok, forms } ->
        { result, new_binding, new_env, new_scope } =  
          :elixir.eval_forms(forms, state.binding, state.env, state.scope)
          new_state = state.update(exec_count: state.exec_count + 1,
                                   binding: new_binding, env: new_env,
                                   scope: new_scope)
          if not req.silent do
            IOPub.send_stdout(inspect(result) <> "\n", req.msg_info)
          end
          # TODO: History
          # TODO: Payload, user variables, user expressions
          { :ok, { [], [], [] }, new_state }
      { :error, { line, error, token } } ->
        { :error, 
          { "parse error", "#{inspect error} for token #{inspect token}", [] },
          state }
    end
  end
end
