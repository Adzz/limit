# Limit

This repo is an exploration of the ideas talked about in this very good post [http://jtfmumm.com/blog/2015/11/17/crdt-primer-1-defanging-order-theory/](http://jtfmumm.com/blog/2015/11/17/crdt-primer-1-defanging-order-theory/) read that, and [part two](http://jtfmumm.com/blog/2015/11/24/crdt-primer-2-convergent-crdts/) first.

The is an exploration of various (not good) implementations of a CvRDTs. The best implementation is that found in the `VectorInts` Module. The aim of the system in this repo is to implement a (conceptually at least) distributed grow only counter. This could be extended to be a very limited distributed rate limiter. Once you've read the blog post step through below:

```elixir
# Our data structures:
cvrdt_1 = %Naive{id: 1, state: 0}
cvrdt_2 = %Naive{id: 2, state: 0}
cvrdt_3 = %Naive{id: 3, state: 0}


# Our nodes
{:ok, node_1} = Agent.start_link(fn -> cvrdt_1 end)
{:ok, node_2} = Agent.start_link(fn -> cvrdt_2 end)
{:ok, node_3} = Agent.start_link(fn -> cvrdt_3 end)

# Our cvrdts implement 3 functions: join/2, value/1 and increment/1
# increment increments the node's state by one.
# value returns what the node thinks the value of the system is (i.e.
# in our example, what it thinks the total number of increments is for
# the whole system. Finally join is how one node can tell another node what
# it's state is.


TheSystem.increment(node_1)
TheSystem.increment(node_1)
# The value of the whole system should be 2
TheSystem.increment(node_2)
TheSystem.increment(node_2)
TheSystem.increment(node_2)
# The value of the whole system should be 5
TheSystem.increment(node_3)
TheSystem.increment(node_3)
# The value of the whole system should be 7

"Node 1's value is: #{TheSystem.value(node_1)}"
"Node 2's value is: #{TheSystem.value(node_2)}"
"Node 3's value is: #{TheSystem.value(node_3)}"

# The idea here is the nodes in the system should be able to tell each other
# about their state, and update their own internal state by joining the other
# nodes state to theirs. In other words we need all of the nodes in our system to
# eventually converge on an internal state of 7. That is, every node should eventually
# have an internal state for the global counter of 7 in the scenario above.

# Now naively we might think that if we want to know the count for the whole
# system, we could just add the counts from each of the nodes together. That's
# certainly what we do. If node_1 incremented twice, and node two 3 times and
# node three twice we add 3 + 2 + 2 to get 7. This will definitely fail:

TheSystem.join(node_1, node_2)
"Node 1's value is: #{TheSystem.value(node_1)}"
"Node 2's value is: #{TheSystem.value(node_2)}"
"Node 3's value is: #{TheSystem.value(node_3)}"
TheSystem.join(node_1, node_3)
"Node 1's value is: #{TheSystem.value(node_1)}"
"Node 2's value is: #{TheSystem.value(node_2)}"
"Node 3's value is: #{TheSystem.value(node_3)}"

# So far so good but now:
TheSystem.join(node_2, node_1)
"Node 1's value is: #{TheSystem.value(node_1)}"
"Node 2's value is: #{TheSystem.value(node_2)}"
"Node 3's value is: #{TheSystem.value(node_3)}"

# The original value of node_1, which would have given us the right answer has changed
# by the time we merge with node_2, meaning simply adding together states is not sufficient.
# Our current join function is not commutative.

# In fact it's worse than this. In a distributed system, we can't (mathematically)
# guarantee exact one delivery (what if the network fails?). Which means if we want
# to guarantee delivery of the message we have to let that message happen multiple times.

# But because we can't rely on exact once delivery, in real life each of the nodes
# might tell each other about their state multiple times. If we use + to join two
# nodes, and two nodes merge more than once, even node_1 will be wrong.

# When we looked at order over integers, we said that the join of two numbers is
# the max of those two numbers. Max is also a commutative function -> try the max
# of 3 and 4 then the max of that and 7. Then try swapping the order around, you
# will always converge on a max of 7.

# Let's try again with max as our joining function:

cvrdt_1 = %Max{id: 1, state: 0}
cvrdt_2 = %Max{id: 2, state: 0}
cvrdt_3 = %Max{id: 3, state: 0}

# Our nodes
{:ok, node_1} = Agent.start_link(fn -> cvrdt_1 end)
{:ok, node_2} = Agent.start_link(fn -> cvrdt_2 end)
{:ok, node_3} = Agent.start_link(fn -> cvrdt_3 end)

TheSystem.increment(node_1)
TheSystem.increment(node_1)
# The value of the whole system should be 2
TheSystem.increment(node_2)
TheSystem.increment(node_2)
TheSystem.increment(node_2)
# The value of the whole system should be 5
TheSystem.increment(node_3)
TheSystem.increment(node_3)
# The value of the whole system should be 7

"Node 1's value is: #{TheSystem.value(node_1)}"
"Node 2's value is: #{TheSystem.value(node_2)}"
"Node 3's value is: #{TheSystem.value(node_3)}"

# Now let's let them gossip:
TheSystem.join(node_1, node_2)
TheSystem.join(node_1, node_3)
TheSystem.join(node_2, node_1)
TheSystem.join(node_2, node_3)
TheSystem.join(node_3, node_2)
TheSystem.join(node_3, node_1)

"Node 1's value is: #{TheSystem.value(node_1)}"
"Node 2's value is: #{TheSystem.value(node_2)}"
"Node 3's value is: #{TheSystem.value(node_3)}"

# They've all converged, which is a step in the right direction, but just on the
# wrong number! We aren't adding anything together, how can we expect to get the
# system total?

# It turns out what we need to do is get a bit more sophisticated in the way we
# store our numbers. We need to be able to take the best of both approaches. We
# do that with a list!

# Instead of storing a number in our state, our state is going to be similar to a
# vector clock. We will store at each index the value of the node at that index.

# This will be clearer if we do it:

# ================ As a list =============================

cvrdt_1 = %VectorInts{id: 0, node_states: [0, 0, 0]}
cvrdt_2 = %VectorInts{id: 1, node_states: [0, 0, 0]}
cvrdt_3 = %VectorInts{id: 2, node_states: [0, 0, 0]}

{:ok, node_1} = Agent.start_link(fn -> cvrdt_1 end)
{:ok, node_2} = Agent.start_link(fn -> cvrdt_2 end)
{:ok, node_3} = Agent.start_link(fn -> cvrdt_3 end)

"Node 1's value is: #{TheSystem.value(node_1)}"
"Node 2's value is: #{TheSystem.value(node_2)}"
"Node 3's value is: #{TheSystem.value(node_3)}"

TheSystem.increment(node_1)
TheSystem.increment(node_1)
# The value of the whole system should be 2
TheSystem.increment(node_2)
TheSystem.increment(node_2)
TheSystem.increment(node_2)
# The value of the whole system should be 5
TheSystem.increment(node_3)
TheSystem.increment(node_3)
# The value of the whole system should be 7

"Node 1's value is: #{TheSystem.value(node_1)}"
"Node 2's value is: #{TheSystem.value(node_2)}"
"Node 3's value is: #{TheSystem.value(node_3)}"

TheSystem.join(node_1, node_2)
TheSystem.join(node_1, node_3)
TheSystem.join(node_2, node_1)
TheSystem.join(node_2, node_3)
TheSystem.join(node_3, node_2)
TheSystem.join(node_3, node_1)

"Node 1's value is: #{TheSystem.value(node_1)}"
"Node 2's value is: #{TheSystem.value(node_2)}"
"Node 3's value is: #{TheSystem.value(node_3)}"

# =========================== As a map =============================

cvrdt_1 = %VectorInts{id: 0, node_states: %{0 => 0, 1 => 0, 2 => 0}}
cvrdt_2 = %VectorInts{id: 1, node_states: %{0 => 0, 1 => 0, 2 => 0}}
cvrdt_3 = %VectorInts{id: 2, node_states: %{0 => 0, 1 => 0, 2 => 0}}
cvrdt_4 = %VectorInts{id: 3, node_states: %{3 => 0}}

{:ok, node_1} = Agent.start_link(fn -> cvrdt_1 end)
{:ok, node_2} = Agent.start_link(fn -> cvrdt_2 end)
{:ok, node_3} = Agent.start_link(fn -> cvrdt_3 end)
{:ok, node_4} = Agent.start_link(fn -> cvrdt_4 end)

"Node 1's value is: #{TheSystem.value(node_1)}"
"Node 2's value is: #{TheSystem.value(node_2)}"
"Node 3's value is: #{TheSystem.value(node_3)}"
"Node 4's value is: #{TheSystem.value(node_4)}"

TheSystem.increment(node_1)
TheSystem.increment(node_1)
# The value of the whole system should be 2
TheSystem.increment(node_2)
TheSystem.increment(node_2)
TheSystem.increment(node_2)
# The value of the whole system should be 5
TheSystem.increment(node_3)
TheSystem.increment(node_3)
# The value of the whole system should be 7

"Node 1's value is: #{TheSystem.value(node_1)}"
"Node 2's value is: #{TheSystem.value(node_2)}"
"Node 3's value is: #{TheSystem.value(node_3)}"

TheSystem.join(node_1, node_2)
TheSystem.join(node_1, node_3)
TheSystem.join(node_2, node_1)
TheSystem.join(node_2, node_3)
TheSystem.join(node_3, node_2)
TheSystem.join(node_3, node_1)

"Node 1's value is: #{TheSystem.value(node_1)}"
"Node 2's value is: #{TheSystem.value(node_2)}"
"Node 3's value is: #{TheSystem.value(node_3)}"

# We can make them talk even more and they will
# not change their answer, until one increments
TheSystem.join(node_1, node_2)
TheSystem.join(node_1, node_3)
TheSystem.join(node_2, node_1)
TheSystem.join(node_2, node_3)
TheSystem.join(node_3, node_2)
TheSystem.join(node_3, node_1)

"Node 1's value is: #{TheSystem.value(node_1)}"
"Node 2's value is: #{TheSystem.value(node_2)}"
"Node 3's value is: #{TheSystem.value(node_3)}"

=================== Handle automatic adding of nodes to the system =============================

cvrdt_1 = %Discovery{id: 0, node_states: %{0 => 0, 1 => 0, 2 => 0}}
cvrdt_2 = %Discovery{id: 1, node_states: %{0 => 0, 1 => 0, 2 => 0}}
cvrdt_3 = %Discovery{id: 2, node_states: %{0 => 0, 1 => 0, 2 => 0}}
cvrdt_4 = %Discovery{id: 3, node_states: %{3 => 0}}

{:ok, node_1} = Agent.start_link(fn -> cvrdt_1 end)
{:ok, node_2} = Agent.start_link(fn -> cvrdt_2 end)
{:ok, node_3} = Agent.start_link(fn -> cvrdt_3 end)
{:ok, node_4} = Agent.start_link(fn -> cvrdt_4 end)

TheSystem.increment(node_1)
TheSystem.increment(node_1)

"Node 1's value is: #{TheSystem.value(node_1)}"
"Node 4's value is: #{TheSystem.value(node_4)}"

TheSystem.join(node_1, node_4)
"Node 1's value is: #{TheSystem.value(node_1)}"
"Node 4's value is: #{TheSystem.value(node_4)}"
TheSystem.join(node_4, node_1)
"Node 1's value is: #{TheSystem.value(node_1)}"
"Node 4's value is: #{TheSystem.value(node_4)}"

TheSystem.increment(node_1)
TheSystem.increment(node_1)
# The value of the whole system should be 2
TheSystem.increment(node_2)
TheSystem.increment(node_2)
TheSystem.increment(node_2)
# The value of the whole system should be 5
TheSystem.increment(node_3)
TheSystem.increment(node_3)

TheSystem.join(node_1, node_2)
TheSystem.join(node_1, node_3)
TheSystem.join(node_1, node_4)
TheSystem.join(node_2, node_1)
TheSystem.join(node_2, node_3)
TheSystem.join(node_2, node_4)
TheSystem.join(node_3, node_2)
TheSystem.join(node_3, node_1)
TheSystem.join(node_3, node_4)
TheSystem.join(node_4, node_1)
TheSystem.join(node_4, node_2)
TheSystem.join(node_4, node_3)

Agent.get(node_1, & &1)
Agent.get(node_2, & &1)
Agent.get(node_3, & &1)
Agent.get(node_4, & &1)

```
