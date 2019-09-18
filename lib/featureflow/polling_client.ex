defmodule Featureflow.PollingClient do
  use GenServer

  @timeout 30000

  def start_link(api_key), do: GenServer.start_link(__MODULE__, api_key)

  @impl true
  def init(api_key), do: {:ok, api_key, @timeout}
end
