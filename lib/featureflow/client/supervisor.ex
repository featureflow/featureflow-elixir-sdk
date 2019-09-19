defmodule Featureflow.Client.Supervisor do
  @moduledoc """
  Supervisor for Featureflow.Client instances
  """

  use Supervisor

  def start_link([api_key]),
    do: Supervisor.start_link(__MODULE__, api_key, name: String.to_atom(api_key))

  def init(api_key) do
    children = [
      {Featureflow.PollingClient, [api_key]},
      {Featureflow.Events, [api_key]}
    ]

    :features = :ets.new(:features, [:set, :named_table, :public])
    Supervisor.init(children, strategy: :one_for_one)
  end
end
