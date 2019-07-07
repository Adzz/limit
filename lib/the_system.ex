defmodule TheSystem do
  def increment(node_1), do: CVRDT.increment(node_1)
  def value(node_1), do: CVRDT.value(node_1)
  def join(node_1, node_2), do: CVRDT.join(node_1, node_2)
end

defimpl CVRDT, for: PID do
  # What happens if you put a pid inside a pid...
  def increment(pid), do: Agent.update(pid, &CVRDT.increment/1)
  def value(pid), do: Agent.get(pid, &CVRDT.value/1)

  def join(pid_1, pid_2) do
    node_2_cvrdt = Agent.get(pid_2, fn x -> x end)

    Agent.update(pid_1, fn x -> CVRDT.join(x, node_2_cvrdt) end)
  end
end
