defmodule Featureflow.User do
  alias __MODULE__

  @type key() :: String.t()

  @type t() :: %User{
          key: key(),
          attributes: %{},
          sessionAttributes: %{}
        }

  defstruct [
    :key,
    attributes: %{},
    sessionAttributes: %{}
  ]
end
