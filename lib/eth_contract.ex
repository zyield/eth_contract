defmodule EthContract do
  @moduledoc """
  Provides a few convenience methods for getting information about tokens from ETH smart contracts. Uses JSON-RPC for requests.
  """

  import EthContract.Util

  alias Ethereumex.HttpClient
  alias ABI.TypeDecoder

  @json_rpc_client Application.get_env(:eth_contract, :json_rpc_client) || HttpClient

  @callback balance_of(map()) :: map()
  @callback owner_of(map()) :: map()
  @callback meta(map()) :: map()
  @callback parse_abi(file_path :: String.t()) :: map()
  @callback decode_data(
    data :: String.t(),
    abi :: String.t(),
    method :: String.t(),
    signatures_key :: String.t()
  ) :: map()
  @callback decode_log(
    data :: String.t(),
    topics :: String.t(),
    abi :: String.t(),
    method :: String.t()
  ) :: map()
  @callback total_supply(map()) :: map()

  @doc """
  Get the wallet address given a contract and a token id

  ## Examples

      iex> EthContract.owner_of(%{token_id: 1, contract: "0x06012c8cf97bead5deae237070f9587f8e7a266d"})
      0x79bd592415ff6c91cfe69a7f9cd091354fc65a18

  """
  def owner_of(%{token_id: token_id, contract: contract}) do
    with {:ok, address } <- @json_rpc_client.eth_call(%{ data: "0x" <> owner_of_hex(token_id), to: contract }) do
      with {:ok, address } <- address |> String.slice(2..-1) |> decode_address do
        {:ok, address}
      else
        err -> { :error, err }
      end
    else
      err -> { :error, err }
    end
  end

  @doc """
  Get the balance given a wallet address. This was tested against ERC20 and ERC721 standard contracts.

  ## Examples

      iex> EthContract.balance_of(%{address: '0x123', contract: '0x234'})
      2

  """
  def balance_of(%{address: address, contract: contract}) do
    with {:ok, signature } <- balance_of_hex(address) do
      with {:ok, balance } <- @json_rpc_client.eth_call(%{ data: "0x" <> signature, to: contract }) do
        {:ok, balance |> bytes_to_int }
      else
        err -> {:error, err }
      end 
    else
      err -> {:error, err }
    end
  end

  @doc """
  Get the account balance given a wallet address.
  """

  def account_balance(%{ address: address }) do
    with {:ok, balance } <- @json_rpc_client.eth_get_balance(address) do
      with {balance, _ } <- balance |> String.slice(2..-1) |> Integer.parse(16) do 
        {:ok, balance }
      else
        err -> {:error, err }
      end
    else
      err ->
        {:error, err}
    end
  end 

  @doc """
  Get the total supply given a contract address. This was tested against ERC20 and ERC721 standard contracts.

  ## Examples

  iex> EthContract.total_supply(%{contract: '0x234'})
  :ok

  """
  def total_supply(%{contract: contract}) do
    with {:ok, total_supply } <- @json_rpc_client.eth_call(%{ data: "0x" <> total_supply_hex(), to: contract}) do
      {:ok, total_supply |> bytes_to_int }
    else
      err -> {:error, err }
    end
  end

  @doc """
  ERC721 Meta. This will return a Map with the meta information associated with a token. You have to provide the name of the method to use (ie. CryptoKitties uses getKitty)

  ## Examples

  iex> abi = EthContract.parse_abi("test/support/crypto_kitties.json")
  iex> EthContract.meta(%{token_id: 45, method: "getKitty", contract: "0x06012c8cf97BEaD5deAe237070F9587f8E7A266d", abi: abi})
  %{
    "birthTime" => 1511417999,
    "cooldownIndex" => 0,
    "generation" => 0,
    "genes" => 626837621154801616088980922659877168609154386318304496692374110716999053,
    "isGestating" => false,
    "isReady" => true,
    "matronId" => 0,
    "nextActionAt" => 0,
    "sireId" => 0,
    "siringWithId" => 0
  }

  """
  def meta(%{token_id: token_id, method: method, contract: contract, abi: abi}) do
    with {:ok, meta } <- @json_rpc_client.eth_call(%{ data: "0x" <> meta_for_hex(token_id, method), to: contract }) do
      case meta do
        "0x" ->
          {:error, "Meta is 0x" }
        meta ->
          with {:ok, output } <- decode_data(meta, abi, method, "outputs") do
            {:ok, output } 
          else
            _err -> 
              {:error, "Error in decode_data"}
          end
      end
          else
            _err -> 
              {:error, "Error in eth_call" }
    end

  end

  # Taken from https://github.com/hswick/exw3/blob/master/lib/exw3.ex#L159
  @doc """
  Parses abi into a map with the name of the method as key.

  ## Examples

  iex> abi = EthContract.parse_abi("test/support/crypto_kitties.json")
  %{}

  """
  def parse_abi(file_path) do
    case File.read(file_path) do
      {:ok, abi } -> Poison.Parser.parse!(abi)
      |> Enum.map(fn x -> {x["name"], x} end)
      |> Enum.into(%{})
      err -> err
    end
  end

  defp trim_data(data) do
    {:ok, trimmed_output } = data
                             |> String.slice(2..-1)
                             |> Base.decode16(case: :lower)

    trimmed_output
  end

  defp output_signature(abi, method, signatures_key) do
    output_types      = Enum.map(abi[method][signatures_key], fn x -> x["type"] end)
    output_names      = Enum.map(abi[method][signatures_key], fn x -> x["name"] end)

    types_signature   = Enum.join(["(", Enum.join(output_types, ","), ")"])
    output_signature  = "#{method}(#{types_signature})"

    %{ output_signature: output_signature, output_names: output_names }
  end

  @doc """
  Decodes general smart contract calls

  """

  def decode_data(data, abi, method, signatures_key \\ "inputs")
  def decode_data("0x", _abi, _method, _signatures_key) do
    {:error, %{}}
  end
  def decode_data(data, abi, method, signatures_key) do
    trimmed_output  = trim_data(data)

    %{ output_signature: output_signature, output_names: output_names } = output_signature(abi, method, signatures_key)

    outputs =
      ABI.decode(output_signature, trimmed_output)
      |> List.first()
      |> Tuple.to_list()
      |> Enum.map(&maybe_encode_binary/1)

    {:ok, combine_data(output_names, outputs)}
  end

  defp maybe_encode_binary( << data :: binary>>) do
    enc = Base.encode16(data, case: :lower)
                        "0x" <> enc
  end
  defp maybe_encode_binary(data), do: data

  defp combine_data(names, items) do
    Enum.zip(names, items)
    |> Enum.into(%{})
  end

  @doc """
  Decodes events that have indexed elements. 

  """
  def decode_log(data, topics, abi, method) when Kernel.length(topics) > 1 do
    trimmed_data = trim_data(data)

    not_indexed = Enum.reject(abi[method]["inputs"], fn x -> x["indexed"] == true end)
    indexed     = Enum.reject(abi[method]["inputs"], fn x -> x["indexed"] == false end)

    output_types_no_index = Enum.map(not_indexed, fn x -> x["type"] end) # ["uint256"]

    types_signature   = Enum.join(["(", Enum.join(output_types_no_index, ","), ")"])
    output_signature  = "#{method}(#{types_signature})"

    # grab last two topics, first one is the event signature
    [ _ | topics ] = topics

    decoded_data = trimmed_data
                   |> ABI.TypeDecoder.decode(ABI.Parser.parse!(output_signature))
                   |> List.first
                   |> Tuple.to_list

    decoded_names = not_indexed
                    |> Enum.map( fn x -> x["name"] end)

    non_indexed_result = combine_data(decoded_names, decoded_data)

    res =
      Enum.zip(indexed, topics)
      |> Enum.map(fn x ->
        { map, data } = x
        type = String.to_atom(map["type"])
        decoded = data
                  |> trim_data
                  |> ABI.TypeDecoder.decode_raw([type])
                  |> List.first
                  |> Base.encode16(case: :lower)

decoded = case type do
  :address -> "0x" <> decoded
end

{map["name"], decoded}
      end)

      indexed_result = res
                       |> Enum.into(%{})

                       {:ok, Map.merge(indexed_result, non_indexed_result) }
  end

  @doc """
  Decodes events with no indexes.

  """
  def decode_log(data, _topics, abi, method) do
    decode_data(data, abi, method)
  end

  defp decode_address("") do 
    {:ok, "0x" } 
  end

  defp decode_address(bytes) do
    {address, _} = TypeDecoder.decode_bytes(bytes, 40, :left)
    {:ok, "0x" <> address }
  end


  defp bytes_to_int("0x") do
    0
  end

  defp bytes_to_int(bytes) do
    bytes
    |> String.slice(2..-1)
    |> Base.decode16!(case: :lower)
    |> TypeDecoder.decode_raw([{:uint, 256}])
    |> List.first
  end
end
