defmodule IElixir.HMAC do
  @moduledoc """
  Signature computation server.
  """
  require Lager

  use GenServer.Behaviour

  def start_link(opts) do
    :gen_server.start_link({ :local, :hmac }, __MODULE__, opts, [])
  end

  @doc """
  Compute a signature using the key given to the signature computation server.
  """
  def compute_sig(header_str, parent_header_str,
                  metadata_str, content_str) do
    :gen_server.call(:hmac, { :compute_sig,
      [header_str, parent_header_str, metadata_str, content_str] })
  end

  ## Callbacks
  
  def init(conn_info) do
    scheme = Keyword.get(conn_info, :signature_scheme, "")
    if scheme != "" do
      if not String.starts_with?(scheme, "hmac-") do
        raise ArgumentError, message: "Invalid HMAC scheme: #{inspect scheme}"
      end
      algo = String.replace(scheme, "hmac-", "", global: false)
      { :ok, { binary_to_atom(algo), Keyword.get(conn_info, :key, "") } }
    else
      { :ok, { nil, "" } }
    end
  end

  # If the key is empty the signature should be empty as well (no
  # authentication).
  def handle_call({ :compute_sig, parts }, _from, state = { _, "" }) do
    { :reply, "", state }
  end
  def handle_call({ :compute_sig, parts }, _from, state = { algo, key }) do
    ctx = Enum.reduce(parts, :crypto.hmac_init(algo, key),
                      &:crypto.hmac_update(&2, &1)) |> :crypto.hmac_final()
    hex = bc <<h :: size(4), l :: size(4)>> inbits ctx,
            do: <<to_hex_char(h), to_hex_char(l)>>
    { :reply, hex, state }
  end

  defp to_hex_char(i) when i >= 0 and i < 10, do: ?0 + i
  defp to_hex_char(i) when i >= 10 and i < 16, do: ?a + (i - 10)
end
