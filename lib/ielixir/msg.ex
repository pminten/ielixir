defrecord IElixir.RawMsg, uuids: [], header: nil, parent_header: nil, 
                          metadata: nil, content: nil, blobs: [] do
  @moduledoc """
  An uninterpreted message.
  """
end

defexception IElixir.SignatureError, message: nil

defmodule IElixir.Msg do
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
        IElixir.RawMsg[
          uuids: uuids, header: header, parent_header: parent_header,
          metadata: metadata, content: content, blobs: blobs
        ]
    end
  end

  @doc """
  Encode a message to binary parts.
  """
  def encode(msg = IElixir.RawMsg[]) do
    # TODO: add signature
    msg.uuids ++ ["<IDS|MSG>"] ++ [
      ExJSON.generate(msg.header), ExJSON.generate(msg.parent_header),
      ExJSON.generate(msg.metadata), ExJSON.generate(msg.content)] ++ msg.blobs
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

  See `IElixir.Msg.decode`.
  """
  def store_part(contents, flags, buffer) do
    buffer = [contents | buffer]
    if :rcvmore in flags do
      { :buffer, buffer }
    else
      { :msg,  IElixir.Msg.decode(:lists.reverse(buffer)) }
    end
  end
end
