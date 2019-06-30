# Limit

This repo is an exploration of the ideas talked about in this very good post [http://jtfmumm.com/blog/2015/11/17/crdt-primer-1-defanging-order-theory/](http://jtfmumm.com/blog/2015/11/17/crdt-primer-1-defanging-order-theory/) read that. Below are just rambling notes of my own, plz ignore, but look at the code if you like.

We are going to look at CRDTs, specifically CvRDTs - convergent conflict free replicated data types. What the hell are those and who the hell are you? What indeed. CvRDTs are a special kind of data type that allow us to be sure we can achieve consensus amongst a bunch of nodes, as long as the data we are converging on adheres to certain properties.

Let's start with a problem and see if we can work our way up to implementing one. The problem is we have many nodes on a network that all need to converge on an answer. Let's imagine we want to count the total number of times the nodes in our network hit an API, so that we can limit it before the API does.

Because it is a distributed system we already accept that the system will take some time to agree on the total number of API calls done by all nodes (there is no global state to track this). But what we want to do ideally is prove that given enough time, all nodes in the network will eventually agree.

Okay so we want every node to eventually know what the other nodes know. To see how let's back up and look at maths. What we need is a join semi-lattice. So what the fuck is that?

### Maths!

Maths! You know maths, that thing you keep meaning to learn more of but never quite get round to it. Specifically let's think about order.

order numbers

A join semi-lattice

we can order numbers with <=

Any two numbers can be ordered with this function (total order)

Not everything has total order. Daughter of relation - it's easy to find examples of 2 humans who can't be sorted this way

Located in example -> no total order.

Now if we think about that relation, and we map out the cities we can see a graph forming.

      earth
      /   \
    Europe Asia
      / \
    England    China
      |   \
    Slough London

With the graph mapped out, we can say that for the set of locations in the diagram, earth is the upper bound.
We can take two locations in that and find the least upper bound LUB (wubbalubba dub dub).

For England and china it is Earth. For Slough and london it is engerland.

A join is the LUB between two elements in the set.

When there is total order the join is always one of the elements.

We can define a function to find the join of two things in a set. If we did that function would have 3 properties

1. Commutativity - any order you get the same answer
2. Associativity - Any grouping you get the same answer - imagine joining 3 places
3. Idempotence - You can do it again and again and again and again and again and again and again and again

So now we can define a join semi-lattice. It is an order where there exists a join for any two elements in the set of things being ordered.

Now how does that relate to CRDTVs ?

> Convergent CRDTs (or CvRDTs) are replicated data structures that, when merged, converge toward a value.

That means, the data they encapsulate must be a join semi-lattice, and they must implement a merge or join function that can return us the LUB of two nodes it gets passed

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `limit` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:limit, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/limit](https://hexdocs.pm/limit).
