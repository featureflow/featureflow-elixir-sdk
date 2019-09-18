defmodule FeatureflowTest do
  use ExUnit.Case
  doctest Featureflow

  test "greets the world" do
    assert Featureflow.hello() == :world
  end
end
