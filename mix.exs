defmodule VendorProcessor.MixProject do
  use Mix.Project

  def project do
    [
      app: :vendor_processor,
      version: "0.1.0",
      elixir: "~> 1.17.3",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:csv, "~> 3.2"},
      {:req, "~> 0.5"}
    ]
  end
end
