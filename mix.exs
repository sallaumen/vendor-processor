defmodule VendorProcessor.MixProject do
  use Mix.Project

  def project do
    [
      app: :vendor_processor,
      version: "0.1.0",
      elixir: "~> 1.17.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [
        tool: ExCoveralls,
        ignore_modules: [
          Support.Factories.Adapters.VicAiFactory,
          Support.Factories.VendorDataFactory
        ]
      ],
      preferred_cli_coverage: :coveralls
    ]
  end

  def application do
    [
      mod: {VendorProcessor.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:csv, "~> 3.2"},
      {:req, "~> 0.5"},
      {:plug, "~> 1.17"},

      # Test deps
      {:ex_machina, "~> 2.8", only: :test},
      {:faker, "~> 0.18", only: :test},
      {:excoveralls, "~> 0.18", only: :test},

      # Dev deps
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
