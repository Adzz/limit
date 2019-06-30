defmodule TheSystem do
  def increment(node_1), do: Agent.update(node_1, &CVRDT.increment/1)
  def value(node_1), do: Agent.get(node_1, &CVRDT.value/1)

  def join(node_1, node_2) do
    node_2_cvrdt = Agent.get(node_2, fn x -> x end)

    Agent.update(node_1, fn x -> CVRDT.join(x, node_2_cvrdt) end)
  end
end
