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
  # alias Featureflow.FeatureRegistration

  @spec init(String.t(), %{}) :: Client.t()
  def init(api_key, _config \\ %{}) do
    Process.whereis(String.to_atom(api_key))
  end
end
