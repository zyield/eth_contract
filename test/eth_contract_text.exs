defmodule EthContractTest do
  use ExUnit.Case
  doctest EthContract

  test "greets the world" do
    assert EthContract.hello() == :world
  end
end
