# EthContract

A set of helper methods to help query ETH smart contracts

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `eth_contract` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:eth_contract, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/eth_contract](https://hexdocs.pm/eth_contract).

## Configuration

Add your JSON RPC provider URL in config.exs

```elixir
config :ethereumex,
  url: "http://"
```

## Usage

Load and parse the ABI

```
abi = EthContract.parse_abi("crypto_kitties.json")
```

Get meta given a token_id and method name

```
EthContract.meta(%{token_id: 45, method: "getKitty", contract: "0x06012c8cf97BEaD5deAe237070F9587f8E7A266d", abi: abi})
```

This will return a map with all the meta:

```
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
```
