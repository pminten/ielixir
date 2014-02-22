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
    Lager.info("Sent message to #{inspect sock}")
  end
  def send_all(sock, [part|parts]) do
    :ok = :erlzmq.send(sock, part, [:sndmore])
    send_all(sock, parts)
  end

  @doc """
  Respond to a message.

  Copies the necessary parts of the original message to the new message
  and sends the message.
  """
  def respond(sock, orig = IElixir.Msg[], msg_type, content) do
    parent_header = [
      msg_id: orig.msg_id,
      msg_type: orig.msg_type,
      session: orig.session,
      username: orig.username
    ]
    new_msg = orig.update(
      msg_id: :uuid.uuid_to_string(:uuid.get_v4(), :binary_standard),
      msg_type: msg_type,
      parent_header: parent_header,
      content: content
    )
    parts = IElixir.MsgConv.encode(new_msg)
    Lager.info("Sending #{inspect parts}")
    send_all(sock, parts)
  end
end
