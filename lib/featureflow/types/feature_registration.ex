defmodule Featureflow.FeatureRegistration do
  alias __MODULE__
  @moduledoc """
  FeatureRegistration type validation and implementtion.
  See https://github.com/featureflow/featureflow-sdk-implementation-guide/blob/master/Implementation/objects/FeatureRegistration.md
  """

  @type t() :: %FeatureRegistration{
          key: String.t(),
          failoverVariant: String.t(),
          variants: [FeatureRegistration.Variant.t()]
        }

  defstruct [
    :key,
    failoverVariant: "off",
    variants: []
  ]

  defmodule Variant do
    alias __MODULE__

    @type t() :: %Variant{
            key: String.t(),
            name: String.t()
          }
    defstruct [
      :key,
      :name
    ]
  end
end
