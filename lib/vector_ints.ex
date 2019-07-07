defmodule VectorInts do
  defstruct [:id, :node_states]
end

defimpl CVRDT, for: VectorInts do
  def increment(%{id: id, node_states: node_states}) when is_list(node_states) do
    updated_states =
      node_states
      |> Enum.with_index()
      |> Enum.map(fn {x, index} ->
        if index == id do
          x + 1
        else
          x
        end
      end)

    %VectorInts{id: id, node_states: updated_states}
  end

  def increment(%{id: id, node_states: node_states}) do
    %VectorInts{id: id, node_states: %{node_states | id => node_states[id] + 1}}
  end

  def value(%VectorInts{node_states: node_states}) when is_list(node_states) do
    Enum.reduce(node_states, 0, fn x, acc -> acc + x end)
  end

  def value(%VectorInts{node_states: node_states}) do
    Enum.reduce(node_states, 0, fn {_k, v}, acc -> acc + v end)
  end

  def join(%VectorInts{id: id, node_states: node_states_1}, %VectorInts{
        node_states: node_states_2
      })
      when is_list(node_states_1) and is_list(node_states_2) do
    updated_states =
      node_states_1
      |> Enum.with_index()
      |> Enum.map(fn {x, index} ->
        # What if the two nodes dont know about one another?
        max(x, Enum.at(node_states_2, index))
      end)

    %VectorInts{id: id, node_states: updated_states}
  end

  def join(%VectorInts{id: id, node_states: node_states_1}, %VectorInts{
        node_states: node_states_2
      }) do
    merged_node_states =
      Enum.reduce(node_states_1, %{}, fn {key, value}, acc ->
        Map.put(acc, key, max(value, Map.fetch!(node_states_2, key)))
      end)

    %VectorInts{id: id, node_states: merged_node_states}
  end
end
