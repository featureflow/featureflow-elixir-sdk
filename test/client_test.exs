defmodule Featureflow.ClientTest do
  use ExUnit.Case, async: false
  doctest Featureflow

  alias Featureflow.{Client, User}
  alias Featureflow.Client.Evaluate

  @defaultFeatureVariant "off"

  @operators ~w(equals contains startsWith endsWith matches in notIn before after greaterThan greaterThanOrEqual lessThan lessThanOrEqual)

  setup context do
    Featureflow.Http.Sandbox.clear()

    client = Featureflow.init("test1")

    Faker.random_between(1, 40)
    |> Faker.Util.list(fn n ->
      feature(enabled: rem(n, 2) == 0, defaultRule: rem(n, 3) == 0)
    end)
    |> Enum.map(&{{client, &1.key}, &1})
    |> (&:ets.insert(:features, &1)).()

    {:ok, Map.put(context, :client, client)}
  end

  describe "Featureflow.Client.evaluate/2 tests" do
    test "Evaluate returns defaultFeatureVariant (off) when client is nil" do
      assert %Evaluate{value: @defaultFeatureVariant} =
               Client.evaluate(nil, Faker.Lorem.word(), %User{})
    end

    test "Evaluate returns offVariantKey (off) for disabled feature", %{client: client} do
      test_feature = feature(enabled: false)

      test_feature
      |> (&{{client, &1.key}, &1}).()
      |> (&:ets.insert(:features, &1)).()

      assert %Evaluate{} = evaluate = Client.evaluate(client, test_feature.key, %User{})
      assert evaluate.featureKey == test_feature.key
      assert evaluate.client == client
      assert evaluate.value == test_feature.offVariantKey
    end

    test "Evaluate returns offVariantKey (off) for undefined feature", %{client: client} do
      assert %Evaluate{} = evaluate = Client.evaluate(client, Faker.Lorem.sentence(), %User{})
      assert evaluate.client == client
      assert evaluate.value == @defaultFeatureVariant
    end

    test "Evaluate returns offVariantKey (off) for client with different APIKey" do
      client = Featureflow.init("test2")
      assert %Evaluate{} = evaluate = Client.evaluate(client, Faker.Lorem.sentence(), %User{})
      assert evaluate.client == client
      assert evaluate.value == @defaultFeatureVariant
    end

    test "Evaluate returns one of variantSplits keys for feature default rule", %{client: client} do
      %{rules: [rule]} = test_feature = feature()

      test_feature
      |> (&{{client, &1.key}, &1}).()
      |> (&:ets.insert(:features, &1)).()

      values = Enum.map(rule.variantSplits, & &1.variantKey)

      assert %Evaluate{} = evaluate = Client.evaluate(client, test_feature.key, %User{})
      assert evaluate.client == client
      assert evaluate.value in values
    end

    test "Evaluate returns one of variantSplits keys for feature w/o conditions", %{
      client: client
    } do
      %{rules: [rule]} = test_feature = feature(conditions: false, defaultRule: false)

      test_feature
      |> (&{{client, &1.key}, &1}).()
      |> (&:ets.insert(:features, &1)).()

      values = Enum.map(rule.variantSplits, & &1.variantKey)

      assert %Evaluate{} = evaluate = Client.evaluate(client, test_feature.key, %User{})
      assert evaluate.client == client
      assert evaluate.value in values
    end

    test "Evaluate returns one of variantSplits keys for feature if conditions met", %{
      client: client
    } do
      %{rules: [rule]} = test_feature = feature(defaultRule: false, operator: "equals")

      test_feature
      |> (&{{client, &1.key}, &1}).()
      |> (&:ets.insert(:features, &1)).()

      values = Enum.map(rule.variantSplits, & &1.variantKey)

      [condition | _] = rule.audience.conditions

      user = %User{
        key: Faker.Lorem.word(),
        attributes: %{
          condition.target => condition.values
        }
      }

      assert %Evaluate{} = evaluate = Client.evaluate(client, test_feature.key, user)
      assert evaluate.client == client
      assert evaluate.value in values
    end
  end

  defp feature(opts \\ []) do
    enabled = Keyword.get(opts, :enabled, true)
    defaultRule = Keyword.get(opts, :defaultRule, true)
    operator = opts[:operator] || Faker.Util.pick(@operators)
    conditions = Keyword.get(opts, :conditions, true)

    %{
      key: Faker.Lorem.word(),
      variationSalt: Faker.Lorem.sentence(),
      enabled: enabled,
      offVariantKey: Faker.Lorem.word(),
      rules: [
        if defaultRule do
          %{
            defaultRule: defaultRule,
            audience: nil,
            variantSplits: [
              %{
                variantKey: Faker.Lorem.word(),
                split: Faker.random_between(0, 100)
              },
              %{
                variantKey: Faker.Lorem.word(),
                split: Faker.random_between(0, 100)
              }
            ]
          }
        else
          %{
            defaultRule: defaultRule,
            audience: %{
              conditions:
                if conditions == true do
                  [
                    %{
                      target: Faker.Lorem.word(),
                      operator: operator,
                      values: Faker.Util.list(5, fn _ -> Faker.random_between(0, 10) end)
                    }
                  ]
                else
                  nil
                end
            },
            variantSplits: [
              %{
                variantKey: Faker.Lorem.word(),
                split: Faker.random_between(0, 50)
              },
              %{
                variantKey: Faker.Lorem.word(),
                split: 100
              }
            ]
          }
        end
      ]
    }
  end

  describe "Featureflow.Client.evaluate_operator/2 tests" do
    test "'equals' works for all types" do
      op = "equals"

      # Equals
      [
        # string
        Faker.Lorem.word(),
        # number
        Faker.random_between(0, 65536),
        # Date or DateTime
        Faker.DateTime.backward(0)
      ]
      |> Enum.each(fn context_value ->
        target_values = [context_value | Faker.Util.list(Faker.random_between(0, 100), & &1)]
        assert Client.evaluate_operator(op, context_value, target_values)
      end)

      # Not equals
      [
        # string
        Faker.Lorem.word(),
        # number
        Faker.random_between(10, 65536),
        # Date or DateTime
        Faker.DateTime.backward(0)
      ]
      |> Enum.each(fn context_value ->
        target_values = [Faker.Util.list(Faker.random_between(0, 100), & &1)]
        refute Client.evaluate_operator(op, context_value, target_values)
      end)
    end

    test "'contains' works for strings" do
      op = "contains"
      # string
      context_value = Faker.Lorem.word()

      len =
        context_value
        |> String.length()
        |> div(2)

      value =
        String.slice(context_value, Faker.random_between(0, len), Faker.random_between(1, len))

      target_values = [value | Faker.Util.list(Faker.random_between(0, 100), & &1)]

      assert Client.evaluate_operator(op, context_value, target_values)

      # Not
      target_values = [
        Faker.StarWars.quote() | Faker.Util.list(Faker.random_between(0, 100), & &1)
      ]

      refute Client.evaluate_operator(op, context_value, target_values)
    end

    test "'startsWith' works for strings" do
      op = "startsWith"
      # string
      context_value = Faker.Lorem.word()

      len =
        context_value
        |> String.length()
        |> div(2)

      value = String.slice(context_value, 0, Faker.random_between(1, len))
      target_values = [value | Faker.Util.list(Faker.random_between(0, 100), & &1)]

      assert Client.evaluate_operator(op, context_value, target_values)

      # Not
      target_values = [
        Faker.StarWars.quote() | Faker.Util.list(Faker.random_between(0, 100), & &1)
      ]

      refute Client.evaluate_operator(op, context_value, target_values)
    end

    test "'endsWith' works for strings" do
      op = "endsWith"
      # string
      context_value = Faker.Lorem.word()

      len =
        context_value
        |> String.length()
        |> div(2)

      value = String.slice(context_value, Faker.random_between(0, len), len * 5)
      target_values = [value | Faker.Util.list(Faker.random_between(0, 100), & &1)]

      assert Client.evaluate_operator(op, context_value, target_values)

      # Not
      target_values = [
        Faker.StarWars.quote() | Faker.Util.list(Faker.random_between(0, 100), & &1)
      ]

      refute Client.evaluate_operator(op, context_value, target_values)
    end

    test "'matches' works for strings" do
      op = "matches"
      # string
      context_value = Faker.Lorem.word()

      len =
        context_value
        |> String.length()
        |> div(2)

      value =
        context_value
        |> String.slice(Faker.random_between(0, len), Faker.random_between(1, len))
        |> (&".*#{&1}.*").()

      target_values = [value | Faker.Util.list(Faker.random_between(0, 100), & &1)]

      assert Client.evaluate_operator(op, context_value, target_values)

      # Not
      target_values = [
        Faker.StarWars.quote() | Faker.Util.list(Faker.random_between(0, 100), & &1)
      ]

      refute Client.evaluate_operator(op, context_value, target_values)
    end

    test "'in' works for strings" do
      op = "in"
      # string
      context_value = Faker.Lorem.word()

      target_values = [context_value | Faker.Util.list(Faker.random_between(0, 100), & &1)]

      assert Client.evaluate_operator(op, context_value, target_values)

      # Not
      target_values = [
        Faker.StarWars.quote() | Faker.Util.list(Faker.random_between(0, 100), & &1)
      ]

      refute Client.evaluate_operator(op, context_value, target_values)
    end

    test "'notIn' works for strings" do
      op = "notIn"
      # string
      context_value = Faker.Lorem.word()

      target_values = [
        Faker.StarWars.quote() | Faker.Util.list(Faker.random_between(0, 100), & &1)
      ]

      assert Client.evaluate_operator(op, context_value, target_values)

      # Not
      target_values = [context_value | Faker.Util.list(Faker.random_between(0, 100), & &1)]

      refute Client.evaluate_operator(op, context_value, target_values)
    end

    test "'before' works for dates" do
      op = "before"

      context_value =
        0
        |> Faker.DateTime.backward()
        |> DateTime.to_iso8601()

      value_true =
        10
        |> Faker.DateTime.forward()
        |> DateTime.to_iso8601()

      target_values = [value_true | Faker.Util.list(Faker.random_between(0, 100), & &1)]

      assert Client.evaluate_operator(op, context_value, target_values)

      # Not
      value_false =
        10
        |> Faker.DateTime.backward()
        |> DateTime.to_iso8601()

      target_values = [value_false | Faker.Util.list(Faker.random_between(0, 100), & &1)]
      refute Client.evaluate_operator(op, context_value, target_values)
    end

    test "'after' works for dates" do
      op = "after"

      context_value =
        0
        |> Faker.DateTime.forward()
        |> DateTime.to_iso8601()

      value_true =
        10
        |> Faker.DateTime.backward()
        |> DateTime.to_iso8601()

      target_values = [value_true | Faker.Util.list(Faker.random_between(0, 100), & &1)]

      assert Client.evaluate_operator(op, context_value, target_values)

      # Not
      value_false =
        10
        |> Faker.DateTime.forward()
        |> DateTime.to_iso8601()

      target_values = [value_false | Faker.Util.list(Faker.random_between(0, 100), & &1)]
      refute Client.evaluate_operator(op, context_value, target_values)
    end

    test "'greaterThan' works for numbers" do
      op = "greaterThan"
      context_value = Faker.random_between(0, 65536)

      target_values = [
        context_value - Faker.random_between(1, context_value)
        | Faker.Util.list(Faker.random_between(0, 100), & &1)
      ]

      assert Client.evaluate_operator(op, context_value, target_values)

      # Not

      target_values = [
        context_value + Faker.random_between(1, context_value)
        | Faker.Util.list(Faker.random_between(0, 100), & &1)
      ]

      refute Client.evaluate_operator(op, context_value, target_values)
    end

    test "'lessThan' works for numbers" do
      op = "lessThan"
      context_value = Faker.random_between(0, 65536)

      target_values = [
        context_value + Faker.random_between(1, context_value)
        | Faker.Util.list(Faker.random_between(0, 100), & &1)
      ]

      assert Client.evaluate_operator(op, context_value, target_values)

      # Not

      target_values = [
        context_value - Faker.random_between(1, context_value)
        | Faker.Util.list(Faker.random_between(0, 100), & &1)
      ]

      refute Client.evaluate_operator(op, context_value, target_values)
    end

    test "'greaterThanOrEqual' works for numbers" do
      op = "greaterThanOrEqual"
      context_value = Faker.random_between(0, 65536)

      # Equal
      target_values_equal = [context_value | Faker.Util.list(Faker.random_between(0, 100), & &1)]

      assert Client.evaluate_operator(op, context_value, target_values_equal)

      # or greater
      target_values_greater = [
        context_value - Faker.random_between(1, context_value)
        | Faker.Util.list(Faker.random_between(0, 100), & &1)
      ]

      assert Client.evaluate_operator(op, context_value, target_values_greater)

      # Not

      target_values = [
        context_value + Faker.random_between(1, context_value)
        | Faker.Util.list(Faker.random_between(0, 100), & &1)
      ]

      refute Client.evaluate_operator(op, context_value, target_values)
    end

    test "'lessThanOrEqual' works for numbers" do
      op = "lessThanOrEqual"
      context_value = Faker.random_between(0, 65536)

      # Equal
      target_values_equal = [context_value | Faker.Util.list(Faker.random_between(0, 100), & &1)]

      assert Client.evaluate_operator(op, context_value, target_values_equal)

      # or less
      target_values_less = [
        context_value + Faker.random_between(1, context_value)
        | Faker.Util.list(Faker.random_between(0, 100), & &1)
      ]

      assert Client.evaluate_operator(op, context_value, target_values_less)

      # Not

      target_values = [
        context_value - Faker.random_between(1, context_value)
        | Faker.Util.list(Faker.random_between(0, 100), & &1)
      ]

      refute Client.evaluate_operator(op, context_value, target_values)
    end

    test "'undefined' works for any type" do
      op = Faker.Lorem.word()
      context_value = Faker.random_between(0, 65536)

      target_values = [Faker.Util.list(Faker.random_between(0, 100), & &1)]

      refute Client.evaluate_operator(op, context_value, target_values)
    end
  end
end
