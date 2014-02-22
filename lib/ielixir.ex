defmodule IElixir do
  require Lager
  use Application.Behaviour

  # See http://elixir-lang.org/docs/stable/Application.Behaviour.html
  # for more information on OTP Applications
  def start(_type, opts) do
    if not Keyword.has_key?(opts, :connection_file) do
      raise ArgumentError, message: "Connection file not specified" 
    end
    # Try to detect whether we're running in iex -S mix. This is of course a
    # very ugly hack.
    # TODO: Find a better way to pass the configuration information to the
    # program.
    if length(System.argv) > 0 do
      conn_file = Enum.reverse(System.argv) |> hd
    else
      conn_file = opts[:connection_file]
    end
    conn_info = File.read!(conn_file)
                |> ExJSON.parse
                |> Enum.map(fn { k, v } -> { binary_to_atom(k), v } end)
    { :ok, ctx } = :erlzmq.context()
    { :ok, pid } = IElixir.Supervisor.start_link([conn_info: conn_info, zmq_ctx: ctx])
    Lager.info("Startup done, conn file: #{conn_file}")
    { :ok, pid, [zmq_ctx: ctx] }
  end

  def stop(state) do
    :erlzmq.term(state[:zmq_ctx])
    Lager.info("Shutdown done")
    :ok
  end

  def main(opts) do
    opts = OptionParser.parse(opts, aliases: [ c: :connection_file ])
    start(:normal, [connection_file: opts[:connection_file]])
  end
end
