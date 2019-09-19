defmodule Featureflow.MixProject do
  use Mix.Project

  def project do
    [
      app: :featureflow,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:poison, "~> 4.0"}
    ]
  end
end
