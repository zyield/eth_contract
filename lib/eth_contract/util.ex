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
    {:ok, address } = address_to_bytes(address)

    ABI.encode("balanceOf(address)", [address])      
    |> Base.encode16(case: :lower)
  end

  def address_to_bytes(address) do
    address
    |> String.slice(2..-1)
    |> Base.decode16(case: :mixed)
  end

  def meta_for_hex(token_id, method) do
    ABI.encode("#{method}(uint256)", [token_id])
    |> Base.encode16(case: :lower)
  end
end
