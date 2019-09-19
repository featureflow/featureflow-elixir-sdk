defmodule Featureflow.User do
  alias __MODULE__

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
