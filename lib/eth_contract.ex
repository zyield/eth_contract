defmodule EthContract do
  @moduledoc """
  Provides a few convenience methods for getting information about tokens from ETH smart contracts. Uses JSON-RPC for requests.
  """

  alias Ethereumex.HttpClient
  alias ABI.TypeDecoder


  @doc """
  Get the wallet address given a contract and a token id 

  ## Examples

      iex> EthContract.owner_of(%{token_id: 1, contract: '0x123'})

  """
  def owner_of(%{token_id: token_id, contract: contract}) do
    {:ok, address } = HttpClient.eth_call(%{
      data: "0x" <> owner_of_hex(token_id),
      to: contract
    })

    address
    |> String.slice(2..-1)
    |> decode_address
  end


  @doc """
  Get the balance given a wallet address. This was tested against ERC20 and ERC721 standard contracts.

  ## Examples

      iex> EthContract.balance_of(%{address: '0x123', contract: '0x234'})
      2

  """
  def balance_of(%{address: address, contract: contract}) do
    {:ok, balance } = HttpClient.eth_call(%{
      data: "0x" <> balance_of_hex(address),
      to: contract
    })

    balance
    |> bytes_to_int
  end


  @doc """
  Get the total supply given a contract address. This was tested against ERC20 and ERC721 standard contracts.

  ## Examples

      iex> EthContract.total_supply(%{contract: '0x234'})

  """
  def total_supply(%{contract: contract}) do
    {:ok, total_supply } = HttpClient.eth_call(%{
      data: "0x" <> total_supply_hex(),
      to: contract
    })

    total_supply
    |> bytes_to_int
  end

  @doc """
  ERC721 Meta. This will return a Map with the meta information associated with a token. You have to provide the name of the method to use (ie. CryptoKitties uses getKitty)

  ## Examples

      iex> abi = EthContract.parse_abi("crypto_kitties.json")
      iex> EthContract.meta(%{token_id: 45, method: "getKitty", contract: "0x06012c8cf97BEaD5deAe237070F9587f8E7A266d", abi: abi})
      %{                                                                                                                                                                                "birthTime" => 1511417999,
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
    {:ok, meta } = HttpClient.eth_call(%{
      data: "0x" <> meta_for_hex(token_id, method),
      to: contract
    })

    meta
    |> decode_meta(abi, method)
  end

  # Taken from https://github.com/hswick/exw3/blob/master/lib/exw3.ex#L159
  @doc """
  Parses abi into a map.

  ## Examples
  
      iex> abi = EthContract.parse_abi("crypto_kitties.json")

  """

  def parse_abi(file_path) do
    file = File.read(Path.join(System.cwd(), file_path))
    
    case file do
      {:ok, abi } -> Poison.Parser.parse!(abi)
                    |> Enum.map(fn x -> {x["name"], x} end)
                    |> Enum.into(%{})
      err -> err
    end
  end

  defp decode_meta(data, abi, method) do
    {:ok, trimmed_output } = data 
                              |> String.slice(2..-1) 
                              |> Base.decode16(case: :lower)

    output_types = Enum.map(abi[method]["outputs"], fn x -> x["type"] end)
    output_names = Enum.map(abi[method]["outputs"], fn x -> x["name"] end)
    types_signature = Enum.join(["(", Enum.join(output_types, ","), ")"])
    output_signature = "#{method}(#{types_signature})"

    outputs =
      ABI.decode(output_signature, trimmed_output)
      |> List.first()
      |> Tuple.to_list()

    Enum.zip(output_names, outputs)
    |> Enum.into(%{})
  end

  defp meta_for_hex(token_id, method) do
    ABI.encode("#{method}(uint256)", [token_id])
    |> Base.encode16(case: :lower)
  end

  defp decode_address(bytes) do
    {address, _} = TypeDecoder.decode_bytes(bytes, 40, :left)
    "0x" <> address 
  end

  defp bytes_to_int(hex) do
    hex
    |> String.slice(2..-1)
    |> Base.decode16!(case: :lower)
    |> TypeDecoder.decode_raw([{:uint, 256}])
    |> List.first
  end

  defp total_supply_hex do
    ABI.encode("totalSupply()", [])
    |> Base.encode16(case: :lower)
  end

  defp owner_of_hex(token_index) do
    ABI.encode("ownerOf(uint256)", [token_index])
    |> Base.encode16(case: :lower)
  end

  defp balance_of_hex(address) do
    {:ok, address } = address_to_bytes(address)

    ABI.encode("balanceOf(address)", [address])      
    |> Base.encode16(case: :lower)
  end

  defp address_to_bytes(address) do
    address
    |> String.slice(2..-1)
    |> Base.decode16(case: :mixed)
  end
end
