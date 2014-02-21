defrecord IElixir.RawMsg, uuids: [], header: nil, parent_header: nil, 
                          metadata: nil, content: nil, blobs: [] do
  @moduledoc """
  An uninterpreted message.
  """
end

defmodule IElixir.Msg do
  @moduledoc """
  Message parsing/serialization.
  """

  @doc """
  Decode a completely received message.

  Throws an exception on decoding failure.
  """
  def decode(parts) do
    case Enum.split_while(parts, &(&1 != "<IDS|MSG>")) do
      { _, [] } -> raise ArgumentError, message: "No <IDS|MSG> found"
      { uuids, [ header_str, parent_header_str, 
                 metadata_str, content_str | blobs ] } ->
        { :ok, header }        = JSEX.decode!(header_str)
        { :ok, parent_header } = JSEX.decode!(parent_header_str)
        { :ok, metadata }      = JSEX.decode!(metadata_str)
        { :ok, content }       = JSEX.decode!(content_str)
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
    msg.uuids ++ ["<IDS|MSG>"] ++ [
      JSEX.encode!(msg.header), JSEX.encode!(msg.parent_header),
      JSEX.encode!(msg.metadata), JSEX.encode!(msg.content)] ++ msg.blobs
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
    if :recvmore in flags do
      { :buffer, buffer }
    else
      { :msg,  IElixir.Msg.decode(:lists.reverse(buffer)) }
    end
  end
end
