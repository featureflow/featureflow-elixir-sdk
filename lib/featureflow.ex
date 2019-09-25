defmodule Featureflow do
  @moduledoc """
  Featureflow main entry point
  Example:
  apiKey
  |> Featureflow.init()
  |> Featureflow.Client.evaluate(feature_key)
  """

  def init(api_key, config \\ %{}) do
    Process.whereis(String.to_atom(api_key))
  end
end
