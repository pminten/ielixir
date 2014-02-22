defrecord IElixir.Msg, uuids: [],
                       msg_id: nil, msg_type: nil,
                       username: nil, session: nil,
                       parent_header: nil,
                       metadata: nil, content: nil, blobs: [] do
  @moduledoc """
  A decoded but otherwise uninterpreted message.

  Compared the over-the-wire message the hmac field is missing and the header
  fields have been merged into the top level IElixir.Msg.
  """
end

defexception IElixir.SignatureError, message: nil

defmodule IElixir.MsgConv do
  @moduledoc """
  Message parsing/serialization.
  """
  require Lager

  @doc """
  Decode a completely received message.

  Throws an exception on decoding failure.
  """
  def decode(parts) do
    case Enum.split_while(parts, &(&1 != "<IDS|MSG>")) do
      { _, [] } -> raise ArgumentError, message: "No <IDS|MSG> found"
      { uuids, [ _sep, sig, header_str, parent_header_str,
                 metadata_str, content_str | blobs ] } ->
        computed_sig = IElixir.HMAC.compute_sig(header_str, parent_header_str,
                                                metadata_str, content_str)
        if computed_sig != "" and sig != computed_sig do
          raise IElixir.SignatureError, message:
            "Invalid signature #{inspect computed_sig}, expected #{inspect sig}"
        end
        header        = ExJSON.parse(header_str)
        parent_header = ExJSON.parse(parent_header_str)
        metadata      = ExJSON.parse(metadata_str)
        content       = ExJSON.parse(content_str)

        IElixir.Msg[
          uuids: uuids,
          msg_id: header["msg_id"], msg_type: binary_to_atom(header["msg_type"]),
          session: header["session"], username: header["username"],
          parent_header: parent_header, metadata: metadata,
          content: content, blobs: blobs
        ]
    end
  end

  @doc """
  Encode a message to binary parts.
  """
  def encode(msg = IElixir.Msg[]) do
    header_pairs = [
      {"msg_id", msg.msg_id}, {"msg_type", msg.msg_type},
      {"session", msg.session}, {"username", msg.username},
    ]
    header_str = ExJSON.generate(header_pairs)
    parent_header_str = ExJSON.generate(msg.parent_header)
    metadata_str = ExJSON.generate(msg.metadata)
    content_str = ExJSON.generate(msg.content)
    sig = IElixir.HMAC.compute_sig(header_str, parent_header_str,
                                   metadata_str, content_str)
    msg.uuids ++ ["<IDS|MSG>", sig, header_str, parent_header_str,
                  metadata_str, content_str] ++ msg.blobs
  end
end

defmodule IElixir.MsgBuffer do
  @moduledoc """
  A buffer to store parts of a message until it is completely processed.
  """

  @doc """
  Create a new buffer.
  """
  def new() do
    []
  end

  @doc """
  Store a part in the buffer.

  Returns either `{ :buffer, new_buffer }` or `{ :msg, decoded_msg }`.

  See `IElixir.MsgConv.decode`.
  """
  def store_part(contents, flags, buffer) do
    buffer = [contents | buffer]
    if :rcvmore in flags do
      { :buffer, buffer }
    else
      { :msg,  IElixir.MsgConv.decode(:lists.reverse(buffer)) }
    end
  end
end
