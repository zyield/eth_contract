defmodule EthContract.Util do
  def total_supply_hex() do
    ABI.encode("totalSupply()", [])
    |> Base.encode16(case: :lower)
  end

  def owner_of_hex(token_index) do
    ABI.encode("ownerOf(uint256)", [token_index])
    |> Base.encode16(case: :lower)
  end

  def balance_of_hex(address) do
    case address_to_bytes(address) do
      {:ok, address } ->
        case ABI.encode("balanceOf(address)", [address]) |> Base.encode16(case: :lower) do
          {:error, _ } -> { :error, "Error decoding data" }
          signature -> 
            {:ok, signature}
        end
       {:error, message } -> { :error, message }
    end
  end

  def address_to_bytes(address) do
    address = address
              |> String.slice(2..-1)

    case Base.decode16(address, case: :mixed) do
      {:ok, address } -> {:ok, address}
      :error -> {:error, "Error converting address to bytes" }
    end
  end

  def meta_for_hex(token_id, method) do
    ABI.encode("#{method}(uint256)", [token_id])
    |> Base.encode16(case: :lower)
  end
end
