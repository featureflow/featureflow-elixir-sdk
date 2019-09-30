defmodule Featureflow.Supervisor do
  @moduledoc """
  Supervisor for Featureflow.Client instances
  """

  use Supervisor

  def start_link(_), do: Supervisor.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    children =
      :featureflow
      |> Application.get_env(:apiKeys, [])
      |> Enum.map(&Supervisor.child_spec({Featureflow.Client.Supervisor, [&1]}, id: &1))

    :features = :ets.new(:features, [:set, :named_table, :public])

    Supervisor.init(children, strategy: :one_for_one)
  end
end
