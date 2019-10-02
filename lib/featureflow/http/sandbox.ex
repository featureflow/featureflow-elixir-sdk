defmodule Featureflow.Http.Sandbox do
  use GenServer

  @spec start_link() :: GenServer.on_start()
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, %{calls: %{}, response: :ok}}
  end

  def clear() do
    GenServer.cast(__MODULE__, :clear)
  end

  def request(method, url, headers, body) do
    GenServer.call(__MODULE__, {:request, {method, url, headers, body}})
  end

  def is_url_requested(url) do
    GenServer.call(__MODULE__, {:url_requested, url})
  end

  def is_url_requested_by_process(url, pid) do
    GenServer.call(__MODULE__, {:url_requested_by_pid, url, pid})
  end

  def is_url_requested_by_me(url) do
    GenServer.call(__MODULE__, {:url_requested_by_pid, url, self()})
  end

  @impl true
  def handle_call({:request, data}, {from, _ref}, %{calls: calls, response: :ok} = state) do
    my_calls =
      calls
      |> Map.get(from, [])
      |> (&[data | &1]).()

    {:reply, {:ok, [], %{}}, %{state | calls: Map.put(calls, from, my_calls)}}
  end

  def handle_call({:url_requested, url}, _from, %{calls: calls, response: :ok} = state) do
    is_called =
      calls
      |> Map.values()
      |> Enum.concat()
      |> List.keymember?(url, 1)

    {:reply, is_called, state}
  end

  def handle_call(
        {:url_requested_by_pid, url, pid},
        _from,
        %{calls: calls, response: :ok} = state
      ) do
    is_called =
      calls
      |> Map.get(pid, [])
      |> List.keymember?(url, 1)

    {:reply, is_called, state}
  end

  def handle_call(msg, _from, state) do
    IO.inspect("Unexpected message #{inspect(msg)} in #{__MODULE__}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast(:clear, state), do: {:noreply, %{state | calls: %{}}}

  def handle_cast(msg, state) do
    IO.inspect("Unexpected message #{inspect(msg)} in #{__MODULE__}")
    {:reply, state}
  end
end
