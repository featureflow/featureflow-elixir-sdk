defmodule Featureflow.Http do
  @http_module Application.get_env(:featureflow, :http_request_module, Featureflow.Http.Live)

  def child_spec(_), do: %{id: __MODULE__, start: {__MODULE__, :start_link, []}}

  def start_link(), do: @http_module.start_link()

  @spec request(atom(), String.t(), headers, term()) ::
          {:ok, headers, map()} | {:error, pos_integer(), String.t()} | {:error, any()}
        when headers: [{String.t(), String.t()}]
  def request(method, url, headers, body) do
    @http_module.request(method, url, headers, body)
  end
end
