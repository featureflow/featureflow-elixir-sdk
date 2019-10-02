defmodule Featureflow.Event do
  alias __MODULE__
  alias Featureflow.Feature
  alias Featureflow.User

  @type t() :: %Event{
          featureKey: Feature.feature_key(),
          evaluatedVariant: String.t(),
          expectedVariant: String.t() | nil,
          user: User.t()
        }

  defstruct [
    :featureKey,
    :evaluatedVariant,
    :expectedVariant,
    :user
  ]
end
