defmodule Featureflow.Feature do
  alias __MODULE__

  @type feature_key() :: String.t()

  @type t :: %Feature{
    key: feature_key(),
    variationSalt: String.t(),
    enabled: boolean(),
    offVariantKey: String.t(),
    rules: [ Feature.Rule.t() ]
  }

  defstruct [
    :key,
    variationSalt: nil,
    enabled: true,
    offVariantKey: "off",
    rules: []
  ]

  defmodule Rule do
    alias __MODULE__

    @type t() :: %Rule{
      defaultRule: boolean(),
      audience: %{
        conditions: [ Rule.Condition.t() ],
      },
      variantSplits: [ Rule.VariantSplit.t() ]
    }

    defstruct [ 
      defaultRule: false,
      audience: %{conditions: nil},
      variantSplits: []
    ]

    defmodule Condition do
      alias __MODULE__

      @type t() :: %Condition{
        target: String.t(),
        operator: String.t(),
        values: [ term() ]
      }

      defstruct [
        :target,
        :operator,
        values: []
      ]
    end

    defmodule VariantSplit do
      alias __MODULE__

      @type t() :: %VariantSplit{
        variantKey: String.t(),
        split: non_neg_integer()
      }

      defstruct [
        :variantKey,
        :split
      ]
    end
  end
end
