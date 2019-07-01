defmodule NaiveTest do
  use ExUnit.Case, async: true

  describe "increment/1" do
    test "increments the value for the given node" do
      assert CVRDT.increment(%Naive{id: 1, state: 0}) == %Naive{id: 1, state: 1}
    end
  end
end
