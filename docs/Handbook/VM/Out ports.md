# Chapter: Output Port Identification in Emu

This chapter explains how output ports are identified in Emu, how VM-level ports relate to network-level ports, and how events travel from a VM instruction to connected nodes in the network.

---

## 1. Architectural Overview

Emu separates port identification into two conceptual layers:

| Layer | What it identifies | Representation |
|-------|--------------------|----------------|
| VM level | Which output slot inside a node | 0-based index |
| Net level | Which physical port in the network | `(node_id, out_port_id)` |

This separation creates a clean abstraction boundary:

- The VM knows only about output indexes.
- The Node translates indexes into concrete port IDs.
- The Network routes events using `(node_id, port_id)` pairs.

---

## 2. VM-Level Output Ports

At VM level, output ports are identified purely by index.

### Relevant VM Instructions

The instruction set includes:

- `Emit` — emit to output index `0`
- `EmitTo idx` — emit to output index `idx`
- `EmitIfNonZero idx` — conditionally emit to output index `idx`

The VM does not know:

- real port IDs
- network topology
- which nodes are connected

It only produces emissions of the form:

    (out_index, value)

Where:

- `out_index` is a 0-based integer
- `value` is the contents of register `A`

### VM View of the World

From the VM’s perspective:

- A node has `N` output ports.
- They are addressed as `0, 1, 2, ..., N-1`.
- `LoadMeta OutPortCount` returns `N`.

The VM has no visibility into actual network identifiers.

---

## 3. Node-Level Port Mapping

Each node stores:

    out_ports : int list

This list represents the actual output port IDs used at the network level.

When a VM emits:

    (out_index, value)

The node resolves it:

    let port_id = List.nth node.out_ports out_index

So the relationship is:

    VM index  →  node.out_ports[index]  →  net-level port_id

### Important Invariant (Current Implementation)

In the current `NodeBuilder` implementation:

    let add_out_port () =
      let id = !next_out_port in
      incr next_out_port;
      out_ports := !out_ports @ [id];
      id

This means:

- Out port IDs are `0, 1, 2, ...`
- `out_ports = [0; 1; 2; ...]`

Therefore:

In the current version, VM output index equals network port ID.

However, this equality is a consequence of the builder design — not a requirement of the architecture. The abstraction layer allows this mapping to change in the future without modifying VM programs.

---

## 4. Network-Level Port Identification

At network level, routing is based on:

    (node_id, out_port_id)

Connections are defined as:

    Net.connect
      { from = (src_node_id, out_port_id);
        to_  = (dst_node_id, in_port) }

The network does not use output indexes. It routes based on concrete port identifiers attached to specific nodes.

### Routing Table Conceptually

    (src_node_id, out_port_id)
        →
    list of (dst_node_id, in_port)

This allows:

- multiple subscribers (fan-out)
- dynamic graph construction and rewiring

---

## 5. End-to-End Event Flow

The complete flow of an emitted value is:

### Step 1 — VM Emits

VM instruction:

    EmitTo 1

VM produces:

    (1, value)

---

### Step 2 — Node Resolves Index

Node translates:

    out_index = 1
    port_id = node.out_ports[1]

Suppose:

    node.out_ports = [10; 20; 30]

Then:

    EmitTo 1 → port_id = 20

Node produces a net-level emission equivalent to:

    from = (node_id, 20)
    payload = value

---

### Step 3 — Network Routes

Network looks up:

    (node_id, 20)

And delivers to all connected destinations:

    (dst_node_id, in_port)

Each destination node then executes its handler for that `in_port`.

---

## 6. Why Two Levels of Identification?

Although currently redundant (because IDs equal indexes), the two-level design provides:

### 6.1 Abstraction Boundary

VM code does not depend on network topology. VM programs can be reused across different network configurations.

### 6.2 Future-Proofing

The builder could later assign:

- sparse IDs
- globally unique IDs
- stable IDs across serialization
- named or hashed IDs

Without changing VM semantics.

### 6.3 Topology Independence

Routing stability does not depend on output ordering inside a node. If port IDs ever become non-sequential, VM programs remain unaffected.

---

## 7. Relationship Summary

### VM-Level

- Identifies outputs by slot index
- Purely local to the node
- Zero-based
- Determined by order of `add_out_port`

### Node-Level

Maintains mapping:

    index → port_id

Bridges VM and network layers.

### Network-Level

Identifies ports by:

    (node_id, port_id)

Handles routing and fan-out.

---

## 8. Conceptual Model

You can think of Emu ports as:

    VM sees:     logical output slots
    Node sees:   logical slots bound to physical port IDs
    Net sees:    concrete addressable ports

Graphically:

    VM           Node                Network
    ----         ----                -------
    EmitTo 1  →  out_ports[1]  →  (node_id, port_id)

---

## 9. Current Practical Implication

In the present implementation:

- VM output index equals net port ID
- Mapping is identity
- Simplification is possible

But the architecture is deliberately designed to support non-identity mappings in the future.

---

## 10. Key Takeaways

1. VM emits using 0-based output indexes.
2. Nodes translate indexes into concrete port IDs.
3. Network routes based on `(node_id, port_id)`.
4. The current builder makes IDs equal indexes.
5. The separation is intentional and enables future extensibility.
