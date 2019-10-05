# featureflow-elixir-sdk
[![][dependency-img]][dependency-url]

> Elixir SDK for the featureflow feature management platform

Get your Featureflow account at [featureflow.io](http://www.featureflow.io)

## Get Started

The easiest way to get started is to follow the [Featureflow quick start guides](http://docs.featureflow.io/docs)

> Alternatively to see featureflow running in action, you can run the example in this repo:
1. Clone this repository
2. Copy config/dev.exs.sample to config/dev.exs
3. Update confid/dev.exs ```apiKey: [ "your-javascript-environment-sdk-key"]``` 
4. Run `$ mix do deps.get, compile` and `$ iex -S mix`
5. Have fun!

## Installation
The SDK is available on ![hex.pm][hex-url].

You can either add it as a dependency in your mix.exs, or install it globally as an archive task.

To add it to a mix project, just add a line like this in your deps function in mix.exs:
```elixir
defp deps do
  [{:featureflow, "~> 0.1.0"}]
end
```
and run
```
mix do deps.get, deps.compile
```

## Usage
Here is a simple example of running your feature that prints "Feature evaluated" on the screen.
```elixir
defmodule MySimpleFeature do
    alias Featureflow.{User, Client}
    alias Featureflow.Client.Evaluate

    def evaluate_my_feature(%User{} = user) do
        api_key = "<your-javascript-environment-sdk-key>"
        api_key
        |> Featureflow.init()
        |> Client.evaluate(:'some-cool-feature', user)
        |> Evaluate.isOn()
        |> maybe_evaluate_my_feature()
    end

    def maybe_evaluate_my_feature(true) do
        # Execute your feature code here
        IO.inspect "Feature evaluated"
    end
    def maybe_evaluate_my_feature(_), do: nil
end
```

[hex-url]: https://hex.pm/packages/
[dependency-url]: https://www.featureflow.io
[dependency-img]: https://www.featureflow.io/wp-content/uploads/2016/12/featureflow-web.png



Further documentation can be found [here](http://docs.featureflow.io/docs)


## About featureflow
* Featureflow is an application feature management tool that allows you to safely and effectively release, manage and evaluate your applications features across multiple applications, platforms and languages.
    * Dark / Silent Release with features turned off
    * Gradual rollout to a percent of users
    * Virtual Rollout and Rollback of features
    * Environment and Component feature itinerary
    * Target features to specific audiences
    * A/B and Multivariant test new feature variants - migrate to the winner
    All without devops, engineering or downtime.
* We have SDKs in the following languages
    * [Javascript] (https://github.com/featureflow/featureflow-javascript-sdk)
    * [Java] (https://github.com/featureflow/featureflow-java-sdk)
    * [NodeJS] (https://github.com/featureflow/featureflow-node-sdk)
    * [ReactJS] (https://github.com/featureflow/react-featureflow-client)
    * [angular] (https://github.com/featureflow/featureflow-ng)
    * [PHP] (https://github.com/featureflow/featureflow-php-sdk)
    * [Elixir] (https://github.com/featureflow/featureflow-elixir-sdk)    
    * [.net] (https://github.com/featureflow/featureflow-dotnet-client)
* Find out more
    * [Docs] http://docs.featureflow.io/docs
    * [Web] https://www.featureflow.io/     


