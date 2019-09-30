defmodule FeatureflowTest do
  use ExUnit.Case
  doctest Featureflow

  setup do
    Featureflow.Http.Sandbox.start_link()
    :ok
  end

  describe "Featureflow.init/2 tests" do
    test "init/1 without config returns Client.t() or pid" do
      assert is_pid(Featureflow.init("test1"))
      #refute Featureflow.Http.sandbox.called()
    end
    test "init/1 without config returns when api_key is invalid" do
      result = Featureflow.init("test")
      refute is_pid(result)
      assert is_nil(result)
      #refute Featureflow.Http.sandbox.called()
    end
  end
end
