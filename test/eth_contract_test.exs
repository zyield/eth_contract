defmodule EthContractTest do
  use ExUnit.Case

  setup do
    abi = EthContract.parse_abi(Path.expand("./support/crypto_kitties.json", __DIR__))
    {:ok, abi: abi }
  end

  describe "decode_log/4" do
    test "it decodes coin Transfer event" do
      abi = %{
        "Transfer" => %{
          "anonymous" => false,
          "inputs" => [
            %{
              "indexed" => true,
              "name" => "from",
              "type" => "address"
            },
            %{
              "indexed" => true,
              "name" => "to",
              "type" => "address"
            },
            %{
              "indexed" => false,
              "name" => "_value",
              "type" => "uint256"
            }
          ],
          "name" => "Transfer",
          "type" => "event"
        }
      }

      {:ok, log_data } = EthContract.decode_log("0x00000000000000000000000000000000000000000000029c0ac134e35dc00000", ["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef", "0x000000000000000000000000d551234ae421e3bcba99a0da6d736074f22192ff", "0x0000000000000000000000008ca78fbaabff9660ae57e949c390162cc1e34c50"], abi, "Transfer")

      assert log_data === %{"_value" => 12323200000000000000000, "from" => "0xd551234ae421e3bcba99a0da6d736074f22192ff", "to" => "0x8ca78fbaabff9660ae57e949c390162cc1e34c50"}
    end

    test "it returns the log data for non indexed event", %{ abi: abi } do
      {:ok, log_data } = EthContract.decode_log("0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b16ab6e23bdbeeab719d8e4c49d6367487625300000000000000000000000000000000000000000000000000000000000cc7f6", ["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"], abi, "Transfer")
      assert log_data == %{"from" => "0x0000000000000000000000000000000000000000", "to" => "0x03b16ab6e23bdbeeab719d8e4c49d63674876253", "tokenId" => 837622}
    end

    test "it decode payload" do
      abi = %{"Birth" => %{"anonymous" => false, "inputs" => [%{"indexed" => false, "name" => "owner", "type" => "address"}, %{"indexed" => false, "name" => "kittyId", "type" => "uint256"}, %{"indexed" => false, "name" => "matronId", "type" => "uint256"}, %{"indexed" => false, "name" => "sireId", "type" => "uint256"}, %{"indexed" => false, "name" => "genes", "type" => "uint256"}], "name" => "Birth", "type" => "event"}}
      {:ok, log_data } = EthContract.decode_log("0x00000000000000000000000006012c8cf97bead5deae237070f9587f8e7a266d00000000000000000000000000000000000000000000000000000000000cf3c80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005a56b411ce01969730ee135ac794a3190622248f6a187534ca1082f03c64", ["0x0a5311bd2a6608f08a180df2ee7c5946819a649b204b554bb8e39825b2c50ad5"], abi, "Birth")
      assert log_data ==  %{
        "genes" => 623494690161459611489819703807996780065503703761012687510071662227766372,
        "kittyId" => 848840,
        "matronId" => 0,
        "owner" => "0x06012c8cf97bead5deae237070f9587f8e7a266d",
        "sireId" => 0
      }
    end

    test "it returns the log data for non indexed event - Birth" do
      abi = %{
        "Birth" => %{
          "anonymous" => false,
          "inputs" => [
            %{"indexed" => false, "name" => "owner", "type" => "address"},
            %{"indexed" => false, "name" => "kittyId", "type" => "uint256"},
            %{"indexed" => false, "name" => "matronId", "type" => "uint256"},
            %{"indexed" => false, "name" => "sireId", "type" => "uint256"},
            %{"indexed" => false, "name" => "genes", "type" => "uint256"}
          ],
          "name" => "Birth",
          "type" => "event"
        }
      }

      {:ok, log_data } = EthContract.decode_log("0x000000000000000000000000ca97a04e562a71d6fc95f335cb6adc5e07e2e8d800000000000000000000000000000000000000000000000000000000000cf31900000000000000000000000000000000000000000000000000000000000cf31000000000000000000000000000000000000000000000000000000000000aea3600005b16b094c770cc312cee71ae56854e588a300009095c11a9ab7bd52084f9", ["0x0a5311bd2a6608f08a180df2ee7c5946819a649b204b554bb8e39825b2c50ad5"], abi, "Birth")

      assert log_data == %{
        "genes" => 628670632552109618658954045183678035112166633548495867316966897081156857,
        "kittyId" => 848665,
        "matronId" => 848656,
        "owner" => "0xca97a04e562a71d6fc95f335cb6adc5e07e2e8d8",
        "sireId" => 715318
      }
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

      {:ok, log_data } = EthContract.decode_log("0x000000000000000000000000000000000000000000000000000000012a05f200", ["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef", "0x00000000000000000000000000b46c2526e227482e2ebb8f4c69e4674d262e75", "0x00000000000000000000000054a2d42a40f51259dedd1978f6c118a0f0eff078"], indexed_abi, "Transfer")

      assert log_data == %{ "to" => "0x54a2d42a40f51259dedd1978f6c118a0f0eff078", "from" => "0x00b46c2526e227482e2ebb8f4c69e4674d262e75", "value" => 5000000000}
    end
  end

  describe "meta/1" do
    test "it returns the meta information associated with a token id", %{ abi: abi } do
      {:ok, meta } = EthContract.meta(%{ token_id: 1, method: "getKitty", contract: "0x06012c8cf97BEaD5deAe237070F9587f8E7A266d", abi: abi})

      assert meta === %{"birthTime" => 1511417999, "cooldownIndex" => 0, "generation" => 0, "genes" => 626837621154801616088980922659877168609154386318304496692374110716999053, "isGestating" => false, "isReady" => true, "matronId" => 0, "nextActionAt" => 0, "sireId" => 0, "siringWithId" => 0}
    end
  end

  describe "owner_of/1" do
    test "it successfully returns the owner of a token id" do
      {:ok, address } = EthContract.owner_of(%{token_id: 1, contract: "0x06012c8cf97bead5deae237070f9587f8e7a266d"})
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
      {:ok, balance } = EthContract.balance_of(%{ address: "0xC0BB964A7e51393e7F89c5513eAadbE5208Dec89", contract: "0x06012c8cf97BEaD5deAe237070F9587f8E7A266d" })
      assert balance == 3
    end
  end

  describe "total_supply/1" do
    test "it returns the total supply method call" do
      {:ok, total_supply } = EthContract.total_supply(%{ contract: "0x06012c8cf97BEaD5deAe237070F9587f8E7A266d"})
      assert total_supply === 837555
    end
  end
end
