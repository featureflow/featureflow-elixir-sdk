defmodule Featureflow.Client do
  @moduledoc """
  This module includes all functions and logic for FeatureflowClient.evaluate from spec.
  It includes functionality from the list below.
  * Operators, 
  * EvaluateHelpers, 
  * Evaluate._calculateVariant

  See the following docs for more details
  https://github.com/featureflow/featureflow-sdk-implementation-guide/blob/master/Implementation/2.FeatureflowClient.md
  https://github.com/featureflow/featureflow-sdk-implementation-guide/blob/master/Implementation/4.EvaluateHelpers.md
  https://github.com/featureflow/featureflow-sdk-implementation-guide/blob/master/Implementation/5.Operators.md
  https://github.com/featureflow/featureflow-sdk-implementation-guide/blob/master/Implementation/3.Evaluate.md
  """

  alias __MODULE__
  alias Featureflow.{Feature, User}
  alias Featureflow.Feature.Rule
  alias Featureflow.Client.Evaluate

  @compile if Mix.env() == :test, do: :export_all

  @defaultFeatureVariant "off"

  @type t() :: pid()

  @doc "FeatureflowClient.evaluate implemetation"
  @spec evaluate(Client.t(), Feature.feature_key(), User.t()) :: Evaluate.t()
  def evaluate(client, feature_key, user) do
    with [{_, feature_map}] <- :ets.lookup(:features, {client, feature_key}),
         {true, _} <- is_enabled(feature_map) do
      %Feature{}
      |> struct(feature_map)
      |> evaluate_rules(user)
      |> Map.put(:client, client)
    else
      {false, default} ->
        %Evaluate{
          client: client,
          value: default,
          featureKey: feature_key,
          user: user
        }

      _ ->
        %Evaluate{
          client: client,
          value: @defaultFeatureVariant,
          featureKey: feature_key,
          user: user
        }
    end
  end

  defp is_enabled(%{enabled: enabled, offVariantKey: offVariantKey}), do: {enabled, offVariantKey}

  @spec evaluate_rules(Feature.t(), User.t()) :: Evaluate.t()
  defp evaluate_rules(%Feature{rules: rules} = feature, user) do
    value = Enum.reduce_while(rules, feature, &maybe_evaluate_rule(struct(%Rule{}, &1), &2, user))

    %Evaluate{
      value: value,
      featureKey: feature.key,
      user: user
    }
  end

  defp maybe_evaluate_rule(%Rule{defaultRule: true} = rule, %Feature{} = feature, user) do
    {:halt, evaluate_rule(rule, feature, user)}
  end

  defp maybe_evaluate_rule(%Rule{audience: %{conditions: nil}} = rule, %Feature{} = feature, user) do
    {:halt, evaluate_rule(rule, feature, user)}
  end

  defp maybe_evaluate_rule(_rule, %Feature{} = feature, nil), do: {:cont, feature}

  defp maybe_evaluate_rule(
         rule,
         %Feature{} = feature,
         %User{attributes: attrs, sessionAttributes: session_attrs} = user
       ) do
    attributes = Map.merge(session_attrs, attrs)

    Enum.reduce(
      rule.audience.conditions,
      {:cont, feature},
      fn
        %{target: nil}, acc ->
          acc

        %{operator: op, target: target, values: vals}, acc ->
          case Enum.drop_while(
                 Map.get(attributes, target, []),
                 fn attr ->
                   # drop_while has inverse logic
                   not evaluate_operator(op, attr, vals)
                 end
               ) do
            [] ->
              acc

            _ ->
              {:halt, evaluate_rule(rule, feature, user)}
          end
      end
    )
  end

  defp evaluate_operator("equals", attr, [val | _]), do: attr == val

  defp evaluate_operator("contains", attr, [val | _]) when is_binary(attr) do
    String.contains?(attr, val)
  end

  defp evaluate_operator("startsWith", attr, [val | _]) when is_binary(attr) do
    String.starts_with?(attr, val)
  end

  defp evaluate_operator("endsWith", attr, [val | _]) when is_binary(attr) do
    String.ends_with?(attr, val)
  end

  defp evaluate_operator("matches", attr, [val | _]) when is_binary(attr) do
    {:ok, regex} = Regex.compile(val)
    String.match?(attr, regex)
  end

  defp evaluate_operator("in", attr, vals) when is_binary(attr), do: attr in vals
  defp evaluate_operator("notIn", attr, vals) when is_binary(attr), do: attr not in vals

  defp evaluate_operator("greaterThan", attr, [val | _]) when is_number(attr), do: attr > val

  defp evaluate_operator("greaterThanOrEqual", attr, [val | _]) when is_number(attr),
    do: attr >= val

  defp evaluate_operator("lessThan", attr, [val | _]) when is_number(attr), do: attr < val
  defp evaluate_operator("lessThanOrEqual", attr, [val | _]) when is_number(attr), do: attr <= val

  defp evaluate_operator("after", attr, [val | _]) when is_binary(attr) do
    with {:ok, first, _} <- DateTime.from_iso8601(attr),
         {:ok, second, _} <- DateTime.from_iso8601(val) do
      DateTime.compare(first, second) == :gt
    else
      _ ->
        false
    end
  end

  defp evaluate_operator("before", attr, [val | _]) when is_binary(attr) do
    with {:ok, first, _} <- DateTime.from_iso8601(attr),
         {:ok, second, _} <- DateTime.from_iso8601(val) do
      DateTime.compare(first, second) == :lt
    else
      _ ->
        false
    end
  end

  defp evaluate_operator(_op, _attr, _vals) do
    false
  end

  defp evaluate_rule(rule, %Feature{variationSalt: variationSalt} = feature, user) do
    variationSalt
    |> calculateHash(feature.key, user.key)
    |> getVariantValue()
    |> getVarintSplitKey(rule.variantSplits)
  end

  defp calculateHash(variationSalt, feature_key, user_key) do
    :crypto.hash(:sha, "#{variationSalt}:#{feature_key}:#{user_key}")
    |> Base.encode16(case: :lower)
    |> String.slice(0..14)
  end

  defp getVariantValue(hash) do
    hash
    |> String.to_integer(16)
    |> rem(100)
    |> Kernel.+(1)
  end

  def getVarintSplitKey(variant_value, vs) do
    Enum.reduce_while(
      vs,
      0,
      fn %{variantKey: key, split: split}, percent ->
        percent_new = percent + split

        if percent_new >= variant_value do
          {:halt, key}
        else
          {:cont, percent_new}
        end
      end
    )
  end
end
