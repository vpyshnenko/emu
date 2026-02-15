# Emu Output Port Model — Formal Specification

## 1. Entities

### VM-level emission

The VM executes a handler and returns:

    emissions : (out_index * value) list

Where:

- out_index ∈ ℕ
- 0 ≤ out_index < OutPortCount
- value ∈ int
- OutPortCount = length(node.out_ports)

VM has no knowledge of:
- node_id
- port_id
- network topology

VM emits purely symbolic output slots.

---

## 2. Node-Level Mapping

Each node has:

    node.id : int
    node.out_ports : int list
    node.handlers : in_port -> program

Invariant (current implementation):

    node.out_ports = [0; 1; ...; N-1]

But architecture does NOT require this.

### Emission Resolution Rule

For each VM emission:

    (out_index, value)

Node produces:

    port_id = node.out_ports[out_index]

Resolved emission:

    ((node.id, port_id), value)

This is the only transformation between VM and network.

---

## 3. Network-Level Routing

Network routing table:

    routing : (node_id * port_id) -> list (node_id * in_port)

Delivery rule:

Given resolved emission:

    ((src_id, port_id), value)

Network computes:

    destinations = routing[(src_id, port_id)]

For each:

    (dst_id, in_port)

Invoke:

    Node.handle_event(dst_id, in_port, value)

---

## 4. Computation Model Summary

Full emission pipeline:

    VM:
        EmitTo k
        → (k, value)

    Node:
        k → node.out_ports[k] = port_id
        → ((node.id, port_id), value)

    Network:
        lookup (node.id, port_id)
        → deliver to subscribers

---

## 5. Structural Separation

| Layer | Knows about | Does not know |
|-------|-------------|---------------|
| VM | output slot index | port_id, node_id |
| Node | index → port_id mapping | network topology |
| Network | (node_id, port_id) routing | VM internals |

---

## 6. Key Property

Current builder ensures:

    port_id = out_index

But this is an implementation coincidence.

Semantically:

    out_index ≠ port_id

The mapping exists by design.

---

## 7. Minimal Semantics

Emission is a pure function:

    resolve(node, (k, v)) =
        let pid = node.out_ports[k] in
        ((node.id, pid), v)

Network delivery is:

    deliver(net, ((nid, pid), v)) =
        for each (dst, in_port) in routing[(nid, pid)]
            enqueue (dst, in_port, v)
