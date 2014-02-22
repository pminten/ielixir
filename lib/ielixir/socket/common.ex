defmodule IElixir.Socket.Common do
  @moduledoc """
  Helper functions for all sockets.
  """
  require Lager

  @doc """
  Create and bind an active socket, based on the desired port field (sans
  "_port").

  A pub socket will not be made active (makes no sense, it doesn't receive
  messages).
  """
  def make_socket(ctx, conn_info, port_field, type) do
    # Sanity check, points in the right direction if conn_info is missing
    if conn_info == nil or not Keyword.has_key?(conn_info, :transport) do
      raise ArgumentError, message: "Invalid conn_info: #{inspect conn_info}"
    end
    url = Enum.join([conn_info[:transport], "://", conn_info[:ip],
                     ":", conn_info[binary_to_atom(port_field <> "_port")]])
    Lager.info("Creating #{port_field} (#{type}) socket, bound to #{url}")
    { :ok, sock } = :erlzmq.socket(ctx, [type, { :active, type != :pub }])
    :ok = :erlzmq.bind(sock, url)
    sock
  end

  @doc """
  Send a multipart message entirely.
  """
  def send_all(sock, [part]) do
    :ok = :erlzmq.send(sock, part, [])
  end
  def send_all(sock, [part|parts]) do
    :ok = :erlzmq.send(sock, part, [:sndmore])
    send_all(sock, parts)
  end

  @doc """
  Send a raw message.

  This is a convenience function handles converting to binary parts and sending
  them.
  """
  def send_rawmsg(sock, rawmsg) do
    IElixir.Msg.encode(rawmsg) |> send_all(sock)
  end
end
