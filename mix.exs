defmodule Featureflow.MixProject do
  use Mix.Project

  def project do
    [
      app: :featureflow,
      version: "0.1.0",
      elixir: "~> 1.8",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
	  name: "Featureflow",
	  homepage_url: "https://featureflow.io",
	  source_url: "https://github.com/featureflow/featureflow-elixir-sdk",
      dialyzer: [
        plt_add_deps: :project
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:hackney],
      extra_applications: [:logger],
      mod: {Featureflow.Application, []}
    ]
  end

  def description() do
    "Elixir SDK for the featureflow feature management platform"
  end

  def package() do
    [
	  name: "featureflow",
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/featureflow/featureflow-elixir-sdk"
	  },

    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hackney, github: "benoitc/hackney"},
      {:poison, "~> 4.0"},
      {:cabbage, "~> 0.3.0"},
      {:faker, "~> 0.7"},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev, :test], runtime: false}
    ]
  end
end
