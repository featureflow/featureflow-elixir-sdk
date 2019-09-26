defmodule Featureflow.Events do
  use GenServer

  alias Featureflow.Client
  alias Featureflow.Event
  alias Featureflow.FeatureRegistration

  def child_spec(args), do: %{id: __MODULE__, start: {__MODULE__, :start_link, args}}

  @spec start_link(String.t(), Client.t()) :: GenServer.on_start()

  def start_link(api_key, client), do: GenServer.start_link(__MODULE__, [api_key, client])

  @spec evaluate(Client.t(), [Event.t()]) :: :ok
  def evaluate(client, events) do
    GenServer.cast(this(client), {:events, events})
  end

  defp this(client) do
    client
    |> Supervisor.which_children()
    |> List.keytake(__MODULE__, 0)
    |> fn {{__MODULE__, pid, _, _}, _} -> pid end.()
  end

  @spec init([String.t() | Client.t()]) :: {:ok, map(), non_neg_integer()}
  @impl true
  def init([api_key, client]) do
    state = %{
      api_key: api_key,
      client: client,
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

    {:ok, state}
  end

  @impl true
  def handle_cast({:register, features}, %{base_url: base_url} = state) do
    request("#{base_url}/register", state, Poison.encode!(features))
  end

  def handle_cast({:events, events}, %{base_url: base_url} = state) do
    request("#{base_url}/events", state, Poison.encode!(events))
  end

  def handle_cast(msg, state) do
    IO.inspect("Unexpected message #{inspect(msg)} in #{__MODULE__}")
    {:noreply, state}
  end

  defp request(url, %{headers: headers}=state, body) do
    with {:ok, 200, _resp_headers, _resp} <- :hackney.request(:post, url, headers, body, []) do
      {:noreply, state}
    else
      {:ok, code, _resp_headers, ref} ->
        {:ok, body} = :hackney.body(ref)
        IO.inspect("Server retunred code #{code} with body #{body}")
        {:noreply, state}

      {:error, error} ->
        IO.inspect("An error #{inspect(error)} occured")
        {:noreply, state}
    end
  end
end
