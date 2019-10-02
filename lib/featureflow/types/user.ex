defmodule Featureflow.User do
  alias __MODULE__

  @moduledoc """
  User type implementation and validation.
  See https://github.com/featureflow/featureflow-sdk-implementation-guide/blob/master/Implementation/objects/User.md
  """

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
