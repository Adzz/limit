defmodule Removal do
  defstruct [:id, :node_states]
end

defimpl CVRDT, for: Removal do
  def increment(%{id: id, node_states: node_states}) do
    %Removal{id: id, node_states: %{node_states | id => node_states[id] + 1}}
  end

  def value(%Removal{node_states: node_states}) do
    Enum.reduce(node_states, 0, fn {_k, v}, acc -> acc + v end)
  end

  def join(%Removal{id: id, node_states: node_states_1}, %Removal{
        node_states: node_states_2
      }) do
    node_1_plus_node_2 =
      Enum.reduce(node_states_1, %{}, fn {key, value}, acc ->
        with {:ok, node_x_state} <- Map.fetch(node_states_2, key) do
          Map.put(acc, key, max(value, node_x_state))
        else
          :error -> Map.put(acc, key, value)
        end
      end)

    node_2_plus_node_1 =
      Enum.reduce(node_states_2, %{}, fn {key, value}, acc ->
        with {:ok, node_x_state} <- Map.fetch(node_states_1, key) do
          Map.put(acc, key, max(value, node_x_state))
        else
          :error -> Map.put(acc, key, value)
        end
      end)

    new_state = Map.merge(node_1_plus_node_2, node_2_plus_node_1)

    # This requires that the keys for the maps be unique globally i think.
    new_system_total =
      Enum.reduce(new_state, 0, fn
        {"total", _}, acc -> acc
        {_k, v}, acc -> acc + v
      end)

    %Removal{
      id: id,
      # Could we cache somehow the state so far, so we can reduce the amount
      # of data needed if a node is removed?
      # node_states: Map.merge(new_state, %{"total" => new_system_total})
      node_states: new_state
    }
  end
end
