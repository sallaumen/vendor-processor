defmodule VendorProcessor.MixProject do
  use Mix.Project

  def project do
    [
      app: :vendor_processor,
      version: "0.1.0",
      elixir: "~> 1.17.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:csv, "~> 3.2"},
      {:req, "~> 0.5"}
    ]
  end
end
