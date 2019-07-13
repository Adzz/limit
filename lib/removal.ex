defmodule Removal do
  defstruct [:id, :node_states]
end

# We need to separate the state from the vector clock?
# Or have the vector clock include it somehow
# %{ 1 => {0,       0}}
#          ^        ^
# vector clock      state

# Now we can mutate state and tick the vector clock up one.
# We do the max on the vector clock to find out what state change wins.
# Then we just need to keep in our state the number of other nodes in the
# system? The operations on that state can then be addition, removal, etc
# of those nodes? Then those nodes can have state which gets changed by something?
# Do we have a node that manages the other nodes? Do we have many that converge?
# is it another system that manages the nodes? Feels like a graph

TheSystem.update(node_1, fn %{id: id, node_states: states} ->
  %{states | id => node_states[id] + 1}
end)

defimpl CVRDT, for: Removal do
  # increment changes to ticking up, and performing some operation on the node's
  # state.

  def update(state, fun) do
    %Removal{id: id, node_states: fun.(state)}
  end

  def increment(%{id: id, node_states: node_states}) do
    %Removal{id: id, node_states: %{node_states | id => node_states[id] + 1}}
  end

  def value(%Removal{node_states: node_states}) do
    Enum.reduce(node_states, 0, fn {_k, v}, acc -> acc + v end)
  end

  def join(%Removal{id: id, node_states: node_states_1}, %Removal{
        node_states: node_states_2
      }) do
    # if a node is removed, add it to our own total, then

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
        {_k, {:removed, value}}, acc -> acc
        {_k, v}, acc -> acc + v
      end)

    # We can now know when a node has been added. So if we merge in a field that
    # another node has that we don't, that will add a node. All good. But what if
    # We get the message about deletion, another node hasn't, they send us a join
    # with the deleted node in it still. We are all good for adding only. You could
    # also make it work with removal only, it think. But to do both you need to be
    # able to know which operation "wins" -> i.e. should i be adding this missing
    # node, or has the node joining with me just not yet deleted it in their state?

    # The way we can usually figure that out is by figuring out the order of events.
    # We do that with a vector clock. Whereby we say these two events, order them
    # but how do we capture the lack of something in a vector clock. Can use a tombestone
    # but then we are back to the same problem, of no node

    # Make node_states a map_set, take the intersection when joining. This will

    %Removal{
      id: id,
      # Could we cache somehow the state so far, so we can reduce the amount
      # of data needed if a node is removed?
      # node_states: Map.merge(new_state, %{"total" => new_system_total})
      node_states: new_state
    }
  end
end
