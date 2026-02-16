# STEP 2 — Static Structure of an FSM Network

This section defines the static structure of an FSM Network.  
Static structure specifies how ontological entities are organized and related.

---

## 1. Node Structure

Each node n ∈ NodeId is defined by the following components.

### 1.1 Input Port Set

A finite set:

    InPorts(n) ⊆ InPortId

This set defines all input ports belonging to node n.

---

### 1.2 Output Port Set

A finite set:

    OutPorts(n) ⊆ OutPortId

This set defines all output ports belonging to node n.

If ordering is required by the execution model, OutPorts(n) is treated as an ordered finite list.

---

### 1.3 Local State Space

Each node has an associated state space:

    Sₙ ⊆ State

This defines all possible local states that node n may assume.

---

### 1.4 Initial Local State

Each node has a distinguished initial state:

    sₙ⁰ ∈ Sₙ

---

### 1.5 Transition Function

Each node defines a deterministic transition function:

    δₙ : Sₙ × InPortId × Value
          → Sₙ × List(OutPortId × Value)

For a given:
- current local state
- input port
- input value

the transition function returns:
- a new local state
- an ordered list of emissions

Each emission is a pair:

    (out_port, value)

such that:

    out_port ∈ OutPorts(n)

---

## 2. Network Connectivity

The connectivity of the network is defined by a routing relation:

    R ⊆ (NodeId × OutPortId) × (NodeId × InPortId)

An element

    ((n₁, op), (n₂, ip)) ∈ R

means that an emission from node n₁ on output port op
is connected to node n₂ at input port ip.

Connectivity constraints:

- op ∈ OutPorts(n₁)
- ip ∈ InPorts(n₂)

---

## 3. Network Definition

An FSM Network is defined as the tuple:

    Network =
      (
        N,
        { InPorts(n) }ₙ,
        { OutPorts(n) }ₙ,
        { Sₙ }ₙ,
        { sₙ⁰ }ₙ,
        { δₙ }ₙ,
        R
      )

Where:

- N is a finite set of NodeIds
- Each node n ∈ N is fully specified by its ports, state space, initial state, and transition function
- R defines connectivity between nodes
