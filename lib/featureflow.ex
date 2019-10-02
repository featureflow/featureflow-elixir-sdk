defmodule Featureflow do
  @moduledoc """
  Featureflow main entry point
  Example:
    apiKey
    |> Featureflow.init(config)
    |> Featureflow.Client.evaluate(feature_key, user)
    |> isOn()
    |> maybe_evaluate_feature_key()
  """

  alias Featureflow.Client
  alias Featureflow.Events
  # alias Featureflow.FeatureRegistration

  @doc "Featureflow.init from the spec"
  @spec init(String.t(), %{}) :: Client.t()
  def init(api_key, config \\ %{}) do
    client =
      api_key
      |> String.to_atom()
      |> Process.whereis()

    case config do
      %{withFeatures: features} when features != [] ->
        :ok = Events.register_features(client, features)
        client

      _ ->
        client
    end
  end
end
