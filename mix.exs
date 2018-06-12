defmodule EthContract.MixProject do
  use Mix.Project

  def project do
    [
      app: :eth_contract,
      version: "0.1.2",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
			name: "ETHContract",
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

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
      {:hexate,  ">= 0.6.0"},
      {:abi, "~> 0.1.8"},
      {:ex_doc, "~> 0.14", only: :dev}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
