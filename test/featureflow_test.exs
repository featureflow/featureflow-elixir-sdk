defmodule FeatureflowTest do
  use ExUnit.Case, async: false
  doctest Featureflow

  setup context do
    Featureflow.Http.Sandbox.clear()
    base_url = Application.get_env(:featureflow, :api_endpoint, "")
    {:ok, Map.put(context, :base_url, base_url)}
  end

  describe "Featureflow.init/2 tests" do
    test "init/1 without config returns Client.t() or pid", %{base_url: base_url} do
      assert is_pid(Featureflow.init("test1"))
      refute Featureflow.Http.Sandbox.is_url_requested("#{base_url}/register")
    end

    test "init/1 without config returns nil when api_key is invalid", %{base_url: base_url} do
      result = Featureflow.init("test")
      refute is_pid(result)
      assert is_nil(result)
      refute Featureflow.Http.Sandbox.is_url_requested("#{base_url}/register")
    end

    test "init/1 with config registers new features", %{base_url: base_url} do
      result =
        Featureflow.init(
          "test1",
          %{
            withFeatures: [
              %{
                key: "test",
                failoverVariant: "off",
                variants: [
                  %{
                    key: "off",
                    name: "Off"
                  }
                ]
              }
            ]
          }
        )

      assert is_pid(result)
      :timer.sleep(100)
      assert Featureflow.Http.Sandbox.is_url_requested("#{base_url}/register")
    end
  end
end
