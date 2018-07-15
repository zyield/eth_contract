defmodule EthContract.MixProject do
  use Mix.Project

  def project do
    [
      app: :eth_contract,
      version: "0.2.3",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      name: "ETHContract",
      elixirc_paths: elixirc_paths(Mix.env),
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description() do
    "A set of helper methods for calling ETH Smart Contracts via JSON RPC."
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "eth_contract",
      # These are the default files included in the package
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Razvan Draghici"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/agilealpha/eth_contract"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ethereumex, "~> 0.3.2"},
      {:abi, "~> 0.1.8"},
      {:ex_doc, "~> 0.14", only: :dev}
    ]
  end
end
