defmodule Featureflow.Events do
  use GenServer

  alias Featureflow.{Client, Event, Http}
  alias Featureflow.FeatureRegistration

  @timeout 30_000
  @max_queue_length 10_000

  def child_spec(args), do: %{id: __MODULE__, start: {__MODULE__, :start_link, args}}

  @spec start_link(String.t(), Client.t()) :: GenServer.on_start()

  def start_link(api_key, client), do: GenServer.start_link(__MODULE__, [api_key, client])

  @spec evaluate(Client.t(), [Event.t()]) :: :ok
  def evaluate(client, events) do
    GenServer.cast(this(client), {:events, events})
  end

  @spec register_features(Client.t(), [FeatureRegistration.t()]) :: :ok
  def register_features(client, features) do
    GenServer.cast(this(client), {:register, features})
  end

  defp this(client) do
    client
    |> Supervisor.which_children()
    |> List.keytake(__MODULE__, 0)
    |> (fn {{__MODULE__, pid, _, _}, _} -> pid end).()
  end

  @spec init([String.t() | Client.t()]) :: {:ok, map(), non_neg_integer()}
  @impl true
  def init([api_key, client]) do
    state = %{
      api_key: api_key,
      client: client,
      events: [],
      base_url:
        Application.get_env(
          :featureflow,
          :api_endpoint,
          "https://app.featureflow.io/api/sdk/v1"
        ),
      headers: [
        "Content-Type": "application/json",
        "User-Agent": "Elixir/#{System.version()}",
        Authorization: "Bearer #{api_key}"
      ]
    }

    {:ok, state, 30}
  end

  @impl true
  def handle_cast({:register, []}, state), do: {:noreply, state, @timeout}

  def handle_cast({:register, features}, %{base_url: base_url, headers: headers} = state) do
    Http.request(:put, "#{base_url}/register", headers, Poison.encode!(features))
    {:noreply, state, @timeout}
  end

  def handle_cast({:events, events}, %{events: old_events} = state) do
    case events ++ old_events do
      e when length(e) >= @max_queue_length ->
        {:noreply, %{state | events: e}, 0}

      e ->
        {:noreply, %{state | events: e}, @timeout}
    end
  end

  def handle_cast(msg, state) do
    IO.inspect("Unexpected message #{inspect(msg)} in #{__MODULE__}")
    {:noreply, state, @timeout}
  end

  @impl true
  def handle_info(:timeout, %{events: []} = state), do: {:noreply, state, @timeout}

  def handle_info(:timeout, %{base_url: base_url, headers: headers, events: events} = state) do
    IO.inspect("Submitting #{length(events)} events")
    Http.request(:post, "#{base_url}/events", headers, Poison.encode!(events))
    {:noreply, %{state | events: []}, @timeout}
  end

  def handle_info(msg, state) do
    IO.inspect("Unexpected message #{inspect(msg)} in #{__MODULE__}")
    {:noreply, state, @timeout}
  end

end
