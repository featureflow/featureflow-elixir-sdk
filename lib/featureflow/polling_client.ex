defmodule Featureflow.PollingClient do
  use GenServer

  alias Featureflow.{Client, Http}

  @timeout 30000

  def child_spec(args), do: %{id: __MODULE__, start: {__MODULE__, :start_link, args}}

  @spec start_link(String.t(), Client.t()) :: GenServer.on_start()

  def start_link(api_key, client), do: GenServer.start_link(__MODULE__, [api_key, client])

  @spec init([String.t() | Client.t()]) :: {:ok, map(), non_neg_integer()}
  @impl true
  def init([api_key, client]) do
    base_url =
      Application.get_env(
        :featureflow,
        :api_endpoint,
        "https://app.featureflow.io/api/sdk/v1"
      )

    state = %{
      api_key: api_key,
      client: client,
      url: "#{base_url}/features",
      headers: [
        "Content-Type": "application/json",
        Authorization: "Bearer #{api_key}"
      ]
    }

    {:ok, state, 0}
  end

  @impl true
  def handle_info(:timeout, %{url: url, client: client, headers: headers} = state) do
    case Http.request(:get, url, headers, "") do
      {:ok, new_headers, features} ->
        features
        |> Enum.map(fn {feature_key, v} -> {{client, feature_key}, v} end)
        |> (&:ets.insert(:features, &1)).()

        {:noreply, %{state | headers: new_headers}, @timeout}

      {:error, _, _} ->
        {:noreply, state, @timeout}

      {:error, _} ->
        {:noreply, state, @timeout}
    end
  end

  def handle_info(msg, state) do
    IO.inspect("Unexpected message #{inspect(msg)} in #{__MODULE__}")
    {:noreply, state, @timeout}
  end
end
