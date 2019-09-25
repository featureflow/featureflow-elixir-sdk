defmodule Featureflow.PollingClient do
  use GenServer

  alias Featureflow.Feature

  @timeout 30000

  def child_spec(args), do: %{id: __MODULE__, start: {__MODULE__, :start_link, args}}

  @spec start_link(String.t(), pid()) :: GenServer.on_start()

  def start_link(api_key, client), do: GenServer.start_link(__MODULE__, [api_key, client])

  @impl true
  def init([api_key, client]) do 
    state = %{
      api_key: api_key,
      client: client,
      url: Application.get_env(:featureflow, :api_endpoint, "https://app.featureflow.io/api/sdk/v1/features"),
      headers: [
        "Content-Type": "application/json",
        "Authorization": "Bearer #{api_key}"
      ]
    }

    {:ok, state, 0}
  end

  @impl true
  def handle_info(:timeout, %{url: url, client: client, headers: headers}=state) do
    with {:ok, 200, resp_headers, resp} <- :hackney.request(:get, url, headers, "", []),
         {:ok, json} <- :hackney.body(resp),
         {:ok, features} <- Poison.decode(json, keys: :atoms) do
      new_headers =
        :proplists.get_value("ETag",resp_headers, nil)
        |> update_etag(headers)

      features
      |> Enum.map(fn {feature_key, v} -> {{client, feature_key}, v} end)
      |> (&(:ets.insert(:features, &1))).()
      {:noreply, %{state | headers: new_headers}, @timeout}
    else
      {:ok, code, _resp_headers, ref} ->
        {:ok, body} = :hackney.body(ref)
        IO.inspect "Server retunred code #{code} with body #{body}"
        {:noreply, state, @timeout}
      {:error, error} -> 
        IO.inspect "An error #{inspect error} occured"
        {:noreply, state, @timeout}
    end
  end
  def handle_info(msg, state) do
    IO.inspect "Unexpected message #{inspect msg} in #{__MODULE__}"
    {:noreply, state, @timeout}
  end

  defp update_etag(nil, headers), do: headers
  defp update_etag(etag, headers), do: Keyword.put(headers, "If-None-Match", etag)
end
