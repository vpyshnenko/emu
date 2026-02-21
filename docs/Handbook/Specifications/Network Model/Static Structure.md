# STEP 2 — Static Structure of a Deterministic Network of Reactive State Machines

This section defines the static structure of the network.

The static structure describes how reactive state machines
are organized and interconnected.

No dynamic behavior is defined in this section.

---

## 1. Node Interface Structure

For each NodeId n, the following are statically defined:

- A finite set of input ports:

      InPorts(n) ⊆ InPortId

- A finite set of output ports:

      OutPorts(n) ⊆ OutPortId

Ports are local to their node.
Input and output ports are distinct.

---

## 2. Local Transition Function

For each NodeId n, there exists a deterministic
local transition function:

      δₙ : State × InPortId × Value
            → State × List(OutPortId × Value)

This function satisfies:

- It is defined only for input ports belonging to InPorts(n).
- For a given (state, input port, value),
  the result is uniquely determined.
- The result consists of:
    - a new local State
    - a finite ordered list of emitted values.

Each emitted value has the form:

      (op, v)

where op ∈ OutPorts(n).

The order of emitted values in this list is semantically significant.

---

## 3. Ordered Subscription Structure

The network contains a static subscription mapping:

      Subs : (NodeId × OutPortId)
              → List(NodeId × InPortId)

For each output endpoint (src, op):

      Subs(src, op) =
          [ (dst₁, ip₁), (dst₂, ip₂), ..., (dst_m, ip_m) ]

This list satisfies:

- Each (dstᵢ, ipᵢ) references a valid node and input port.
- The list is finite.
- The order of elements is part of the static structure.
- Duplicate entries are allowed.

If a pair (dst, ip) appears k times in Subs(src, op),
then delivery to that destination occurs k times,
in the specified order.

Thus, the network is an ordered directed multigraph.

---

## 4. Semantics of Ordered Subscriptions

The ordered list Subs(src, op):

- Determines the order in which destinations receive delivered events.
- Determines the order in which resulting emissions
  are appended to the global FIFO frontier.
- Is preserved exactly as declared during network construction.

Reordering subscriptions may change observable behavior
in the presence of feedback or shared downstream nodes.

Therefore, subscription order is semantically significant.

TODO
Update rest of the Specifications from "routing as a set R" to "routing as an ordered multilist Subs"
Subs(src, op) = ordered list derived from R ===> Subs(src, op) is the statically defined ordered subscription list.

After these updates, Emu system becomes:

Deterministic reactive network over an ordered directed multigraph.
---

## 5. Well-Formedness Conditions

The static structure satisfies:

1. For every (dst, ip) ∈ Subs(src, op):

       op ∈ OutPorts(src)
       ip ∈ InPorts(dst)

2. For every NodeId n:

       δₙ only produces output ports in OutPorts(n).

3. The set of nodes is finite.

4. For every (src, op), Subs(src, op) is finite.

---

## 6. Network Definition

A Network consists of:

- A finite set of NodeIds.
- For each node:
    - its input ports,
    - its output ports,
    - its local transition function δₙ.
- An ordered subscription mapping Subs.

The mapping Subs fully defines connectivity,
including ordering and multiplicity.

No additional routing relation is assumed.