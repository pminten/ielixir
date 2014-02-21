defmodule IElixir.Kernel do
  @moduledoc """
  The kernel process proper.
  """
  use GenServer.Behaviour

  def start_link(opts) do
    :gen_server.start_link({ :local, :kernel }, __MODULE__, opts, [])
  end
end
