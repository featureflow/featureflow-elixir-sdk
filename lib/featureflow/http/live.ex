defmodule Featureflow.Http.Live do
  def start_link(), do: {:ok, self()}

  def request(method, url, headers, body) do
    with {:ok, 200, resp_headers, resp} <- :hackney.request(method, url, headers, body, []),
         {:ok, json} <- :hackney.body(resp),
         {:ok, data} <- Poison.decode(json, keys: :atoms) do
      new_headers =
        :proplists.get_value("ETag", resp_headers, nil)
        |> update_etag(headers)
      {:ok, new_headers, data}
    else
      {:ok, code, _resp_headers, ref} ->
        {:ok, body} = :hackney.body(ref)
        IO.inspect("Server retunred code #{code} with body #{body}")
        {:error, code, body}

      {:error, error} ->
        IO.inspect("An error #{inspect(error)} occured")
        {:error, error}
    end
  end

  defp update_etag(nil, headers), do: headers
  defp update_etag(etag, headers), do: [{"If-None-Match", etag} | headers]
end
