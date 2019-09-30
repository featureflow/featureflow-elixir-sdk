defmodule Featureflow.Http.Sandbox do
  use GenServer

  @spec start_link() :: GenServer.on_start()
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, %{calls: [], response: :ok}}
  end

  def request(method, url, headers, body) do
    GenServer.call(__MODULE__, {:request, {method, url, headers, body}})
  end

  def handle_call({:request, data}, _from, %{calls: calls, response: :ok} = state) do
    {:reply, {:ok, [], %{}}, %{state | calls: [data | calls]}}
  end

  def handle_call(msg, _from, %{calls: calls, response: :ok} = state) do
    IO.inspect("Unexpected message #{inspect(msg)} in #{__MODULE__}")
    {:reply, :ok, state}
  end
end
