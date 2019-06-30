defmodule NodeTest do
  use ExUnit.Case

  describe "increment/1" do
    test "increments the value for the given node" do
      assert Node.increment(%Node{id: 1, node_states: %{1 => 0}}) == %Node{
               id: 1,
               node_states: %{1 => 1}
             }
    end
  end

  describe "system_value/1" do
    test "sums all of the values in node_states" do
      node_states = %{1 => 15, 2 => 7}

      assert Node.system_value(%Node{id: 1, node_states: node_states}) == 22
    end
  end

  describe "merge/2" do
    test "takes the co-ordinate wise max of the two node states and returns that" do
      node_1 = %Node{id: 1, node_states: %{1 => 15, 2 => 7}}
      node_2 = %Node{id: 2, node_states: %{1 => 15, 2 => 8}}

      assert Node.merge(node_1, node_2) == %Node{id: 1, node_states: %{1 => 15, 2 => 8}}
    end
  end
end
