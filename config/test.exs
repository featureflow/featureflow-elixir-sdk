use Mix.Config

config :featureflow,
  http_request_module: Featureflow.Http.Sandbox,
  api_endpoint: "http://localhost",
  apiKeys: [
    "test1",
    "test2"
  ]
