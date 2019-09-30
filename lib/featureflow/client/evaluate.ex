defmodule Featureflow.Client.Evaluate do
  alias __MODULE__
  alias Featureflow.Client
  alias Featureflow.{User, Events, Event}

  @type t() :: %Evaluate{
          client: Client.t(),
          value: String.t(),
          featureKey: Feature.feature_key(),
          user: User.t()
        }
  defstruct [
    :client,
    :value,
    :featureKey,
    :user
  ]

  @spec value(Evaluate.t()) :: String.t()
  @doc "Evaluate.value() returns raw evaluated value"
  def value(%Evaluate{value: value} = evaluate) do
    publish_evaluate(evaluate, nil)
    value
  end

  @doc "Evaluate.is() checks if evaluate value is equal to expected one"
  @spec is(Evaluate.t(), String.t()) :: boolean()
  def is(%Evaluate{value: value} = evaluate, variant) do
    publish_evaluate(evaluate, variant)
    value == variant
  end

  @doc "Evaluate.isOn() checks if evaluate value is 'on'"
  @spec isOn(Evaluate.t()) :: boolean()
  def isOn(evaluate), do: is(evaluate, "on")

  @doc "Evaluate.isOff() checks if evaluate value is 'off'"
  @spec isOff(Evaluate.t()) :: boolean()
  def isOff(evaluate), do: is(evaluate, "off")

  defp publish_evaluate(
         %Evaluate{
           client: client,
           value: value,
           featureKey: feature_key,
           user: user
         },
         expected
       ) do
    event = %Event{
      featureKey: feature_key,
      evaluatedVariant: value,
      expectedVariant: expected,
      user: user
    }

    :ok = Events.evaluate(client, [event])
    value
  end
end
