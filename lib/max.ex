defmodule Max do
  defstruct [:id, :state]
end

defimpl CVRDT, for: Max do
  def increment(cvrdt = %{state: state}), do: %{cvrdt | state: state + 1}
  def value(%{state: state}), do: state

  def join(%{id: id, state: state_1}, %{state: state_2}) do
    %Max{id: id, state: max(state_1, state_2)}
  end
end
