defmodule EthContractTest do
  use ExUnit.Case

  setup do
    abi = EthContract.parse_abi(Path.expand("./support/crypto_kitties.json", __DIR__))
    {:ok, abi: abi }
  end

  describe "decode_log/4" do
    test "it returns the log data for non indexed event", %{ abi: abi } do
      log_data = EthContract.decode_log("0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b16ab6e23bdbeeab719d8e4c49d6367487625300000000000000000000000000000000000000000000000000000000000cc7f6", ["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"], abi, "Transfer")
      assert log_data === %{"from" => "0x0000000000000000000000000000000000000000", "to" => "0x03b16ab6e23bdbeeab719d8e4c49d63674876253", "tokenId" => 837622}
    end

    test "it returns the log data for indexed event" do
      indexed_abi = %{
        "Transfer" => %{
            "anonymous" => false,
            "inputs" => [
                  %{"indexed" => true, "name" => "from", "type" => "address"},
                  %{"indexed" => true, "name" => "to", "type" => "address"},
                  %{"indexed" => false, "name" => "value", "type" => "uint256"}
                ],
            "name" => "Transfer",
            "type" => "event"
        }
      }

      log_data = EthContract.decode_log("0x000000000000000000000000000000000000000000000000000000012a05f200", ["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef", "0x00000000000000000000000000b46c2526e227482e2ebb8f4c69e4674d262e75", "0x00000000000000000000000054a2d42a40f51259dedd1978f6c118a0f0eff078"], indexed_abi, "Transfer")

      assert log_data == %{ "to" => "0x54a2d42a40f51259dedd1978f6c118a0f0eff078", "from" => "0x00b46c2526e227482e2ebb8f4c69e4674d262e75", "value" => 5000000000}
    end
  end

  describe "meta/1" do
    test "it returns the meta information associated with a token id", %{ abi: abi } do
      meta = EthContract.meta(%{ token_id: 1, method: "getKitty", contract: "0x06012c8cf97BEaD5deAe237070F9587f8E7A266d", abi: abi})
      assert meta === %{"birthTime" => 1511417999, "cooldownIndex" => 0, "generation" => 0, "genes" => 626837621154801616088980922659877168609154386318304496692374110716999053, "isGestating" => false, "isReady" => true, "matronId" => 0, "nextActionAt" => 0, "sireId" => 0, "siringWithId" => 0}
    end
  end

  describe "owner_of/1" do
    test "it successfully returns the owner of a token id" do
      address = EthContract.owner_of(%{token_id: 1, contract: "0x06012c8cf97bead5deae237070f9587f8e7a266d"})
      assert address === "0x79bd592415ff6c91cfe69a7f9cd091354fc65a18" 
    end
  end

  describe "parse_abi/2" do
    test "it successfully parses the abi into a Map", %{ abi: abi } do
      keys = abi
             |> Map.keys

      assert Kernel.length(keys) == 65
    end
  end

  describe "balance_of/1" do
    test "it returns the balance_of for address" do
      balance = EthContract.balance_of(%{ address: "0xC0BB964A7e51393e7F89c5513eAadbE5208Dec89", contract: "0x06012c8cf97BEaD5deAe237070F9587f8E7A266d" })
      assert balance == 3
    end
  end

  describe "total_supply/1" do
    test "it returns the total supply method call" do
      total_supply = EthContract.total_supply(%{ contract: "0x06012c8cf97BEaD5deAe237070F9587f8E7A266d"})
      assert total_supply === 837555
    end
  end
end
