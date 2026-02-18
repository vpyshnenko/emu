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
    - a finite ordered list of emitted values

Each emitted value has the form:

      (op, v)

where op ∈ OutPorts(n).

---

## 3. Connectivity Relation

The network contains a static connectivity relation:

      R ⊆ (NodeId × OutPortId)
           ×
           (NodeId × InPortId)

An element of R has the form:

      ((src, op), (dst, ip))

and means:

- values emitted at output port op of node src
  are routed to input port ip of node dst.

---

## 4. Subscriber Ordering

For each output endpoint (src, op),
define the ordered subscriber list:

      Subs(src, op) =
          [ (dst₁, ip₁), (dst₂, ip₂), ..., (dst_m, ip_m) ]

such that:

      ((src, op), (dstᵢ, ipᵢ)) ∈ R

The order of this list is part of the static structure.

---

## 5. Well-Formedness Conditions

The static structure satisfies:

1. For every ((src, op), (dst, ip)) ∈ R:

       op ∈ OutPorts(src)
       ip ∈ InPorts(dst)

2. For every NodeId n:

       δₙ only produces output ports in OutPorts(n).

3. The set of nodes is finite.

---

## 6. Network Definition

A Network consists of:

- A finite set of NodeIds
- For each node:
    - its input ports
    - its output ports
    - its local transition function
- A static connectivity relation R
- An ordered subscriber list derived from R
