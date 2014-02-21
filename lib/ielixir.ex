defmodule IElixir do
  use Application.Behaviour

  # See http://elixir-lang.org/docs/stable/Application.Behaviour.html
  # for more information on OTP Applications
  def start(_type, opts) do
    if not Keyword.has_key?(opts, :connection_file) do
      raise ArgumentError, message: "Connection file not specified" 
    end
    conn_info = File.read!(opts[:connection_file]) |> JSEX.decode!
    { :ok, ctx } = :erlzmq.context()
    { :ok, pid } = IElixir.Supervisor.start_link([conn_info: conn_info, zmq_ctx: ctx])
    { :ok, pid, [zmq_ctx: ctx] }
  end

  def stop(state) do
    :erlzmq.term(state[:zmq_ctx])
    :ok
  end

  def main(opts) do
    opts = OptionParser.parse(opts, aliases: [ c: :connection_file ])
    start(:normal, [connection_file: opts[:connection_file]])
  end
end
