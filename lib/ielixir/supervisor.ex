defmodule IElixir.Supervisor do
  use Supervisor.Behaviour

  def start_link(opts) do
    :supervisor.start_link(__MODULE__, opts)
  end

  def init(opts) do
    children = [
      worker(IElixir.Socket.Stdin, [opts]),
      worker(IElixir.Socket.Control, [opts]),
      worker(IElixir.Socket.Heartbeat, [opts]),
      worker(IElixir.Socket.Shell, [opts]),
      worker(IElixir.Socket.IOPub, [opts]),
      worker(IElixir.Kernel, [[]])
    ]

    supervise(children, strategy: :one_for_all)
  end
end
