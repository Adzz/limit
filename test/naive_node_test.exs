defmodule NaiveNodeTest do
  use ExUnit.Case, async: true

  describe "increment/1" do
    test "increments the value for the given node" do
      assert NaiveNode.increment(%NaiveNode{id: 1, state: 0}) == %NaiveNode{id: 1, state: 1}
    end
  end
end
