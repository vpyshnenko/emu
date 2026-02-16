# Emu: Portable Core Specification (Language-Neutral)

## 0. Conventions
- Integers are unbounded mathematical integers unless the implementation chooses a fixed size.
- Lists preserve order.
- “Fail” means a runtime error (implementation-defined handling), but must not silently continue.

---

## 1. Core Data Model (Normative)

### 1.1 Identifiers and Values
- `NodeId : int`
- `PortId : int`
- `InPort : int`
- `OutIndex : int`   // VM-level output slot index
- `Value : int`      // event payload

### 1.2 Events
- `Event = (dst : NodeId, in_port : InPort, payload : Value)`

### 1.3 Routing (Network Topology)
Routing is a mapping:

- `Routing : (NodeId, PortId) -> List[(NodeId, InPort)]`

Interpretation:
- `(srcNode, srcPort)` delivers to zero or more `(dstNode, dstInPort)` subscribers.

### 1.4 Node
A node is:

- `Node = {`
  - `id : NodeId`
  - `state : List[int]`          // persistent state snapshot (initial)
  - `vm_cfg : VmCfg`             // stack/memory/step limits
  - `handlers : Map[InPort -> Program]`
  - `out_ports : List[PortId]`   // output port IDs in slot order
- `}`

**VM output slot order:** slot `k` corresponds to `out_ports[k]`.

### 1.5 Network
- `Net = { nodes : Map[NodeId -> Node], routing : Routing }`

### 1.6 Runtime State
- `Runtime = { net : Net, queue : List[Event], lifetime : int, history : List[Step] }`

---

## 2. VM: Abstract Machine (Normative)

### 2.1 VM State
VM runs a handler program with:

- `stack : List[int]`
- `regA : int`
- `mem : Array[int]`          // size = vm_cfg.mem_size
- `meta : { node_id, in_port_count, out_port_count }`
- `pc : int`
- `steps_remaining : int`
- `emissions : List[(OutIndex, Value)]`

Initial VM state for handling an inbound event `(payload)`:
- `stack := []`
- `regA := payload`
- `mem := load(node.state) into mem[0..]` (rest zeros)
- `meta := { node_id = node.id, out_port_count = len(node.out_ports), in_port_count = size(node.handlers) }`
- `pc := 0`
- `steps_remaining := vm_cfg.max_steps`
- `emissions := []`

### 2.2 VM Termination
VM execution terminates when:
- `Halt` is executed, OR
- `steps_remaining == 0` (fail or forced halt — must be specified by implementation), OR
- `pc` moves past program bounds (fail unless treated as implicit halt — pick one and document).

### 2.3 Emission Semantics (Key)
When VM executes an emit instruction targeting slot `k`, it appends:

- `emissions.append( (k, regA) )`

Constraint:
- `0 <= k < meta.out_port_count` else fail.

VM returns:
- updated `mem`
- `emissions`

---

## 3. Node Semantics (Normative)

Node handling is a pure transition:

### 3.1 Handle Event
Given `node` and inbound event `(in_port, payload)`:

1. Lookup program:
   - `prog := node.handlers[in_port]` else fail.

2. Run VM:
   - `result := VM.run(node.vm_cfg, prog, payload, node.state, meta(node))`

3. Update node state:
   - `node'.state := dump(result.mem)` (exact dump format must be specified: usually mem[0..mem_size-1] as list)

4. Resolve VM emissions to network ports:
   For each `(k, v)` in `result.emissions`:
   - `port_id := node.out_ports[k]` else fail.
   - produce net emission `((node.id, port_id), v)`

Return:
- `node'`
- `net_emissions : List[((NodeId, PortId), Value)]`

---

## 4. Network Semantics (Normative)

### 4.1 Deliver One Net Emission
Given `((src_id, port_id), value)`:

- `subs := routing[(src_id, port_id)]` (empty list if none)
- produce events:
  - for each `(dst, in_port)` in `subs`:
    - `(dst, in_port, value)`

Return list of `Event`.

---

## 5. Runtime Semantics (Normative)

### 5.1 One Step
Runtime state:

- `queue = [e0, e1, ...]`

If queue empty: no-op / terminate.

Else let `e0 = (dst, in_port, payload)`.

1. Decrement lifetime:
   - if `lifetime == 0` → stop/fail (implementation choice, but must be deterministic)
   - `lifetime := lifetime - 1`

2. Apply node transition:
   - `(node', net_emits) := handle_event(net.nodes[dst], in_port, payload)`

3. Update node in net:
   - `net.nodes[dst] := node'`

4. Expand net emissions into new events:
   - `new_events := concat( deliver(em) for em in net_emits )`

5. Update queue (FIFO):
   - `queue := [e1, e2, ...] ++ new_events`

6. Append trace step into history (optional but recommended):
   - record input event, produced net_emits, produced new_events, snapshot id, etc.

### 5.2 Avalanche (Drain Queue)
Repeatedly apply One Step until:
- queue becomes empty, OR
- lifetime exhausted.

### 5.3 Schedule
A “schedule” is a list of initial events.
For each scheduled event:
- enqueue it
- run avalanche

---

## 6. Output Port Identification (Normative Summary)

- VM emits by **OutIndex** (slot number): `0..N-1`.
- Node resolves `OutIndex k` using `out_ports[k]` to obtain **PortId**.
- Network routing uses `(NodeId, PortId)` as the source key.

Note: In the current builder implementation, `out_ports = [0..N-1]`, so `PortId == OutIndex`, but the spec does not require this.

---

## 7. Minimal Reimplementation Checklist

A conforming implementation must:
- implement VM with `regA`, `stack`, `mem`, `emissions`
- implement `handle_event` (VM run + state update + resolve emissions)
- implement routing expansion to events
- implement FIFO queue runtime with lifetime bound
- preserve emission ordering as produced by VM (list order)
- preserve subscriber delivery ordering as stored in routing (list order), or declare ordering as unspecified and treat as a multiset

(Choose and document ordering rules; they matter for deterministic replay.)
