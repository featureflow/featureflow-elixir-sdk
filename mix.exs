defmodule Featureflow.MixProject do
  use Mix.Project

  def project do
    [
      app: :featureflow,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
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
