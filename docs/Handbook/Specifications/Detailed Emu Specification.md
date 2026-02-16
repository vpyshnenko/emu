# Emu Core Specification (Portable, Normative)

This document specifies Emu’s observable behavior and essential logic so it can be reimplemented in any language.

---

## 1. Core Types

### 1.1 Scalars
- `Int` : mathematical integer (implementation may use fixed-width with defined overflow behavior)
- `NodeId, InPort, OutIndex, PortId` : `Int`
- `Value` : `Int`

### 1.2 Instructions
An instruction is one of:

Stack / arithmetic:
- `Pop`
- `PushConst(n:Int)`
- `Add`
- `AddMod`
- `LogStack`

Accumulator A:
- `PushA`
- `PopA`
- `PeekA`

Memory:
- `Load(i:Int)`
- `Store(i:Int)`
- `LoadMeta(m:MetaIndex)`

Emission:
- `Emit`                 // emit to slot = top-of-stack
- `EmitTo(k:Int)`         // emit to slot k
- `EmitIfNonZero(k:Int)`  // if top-of-stack != 0 then emit to slot k

Control:
- `Halt`
- `HaltIfEq(n:Int, x:Int)` // if nth stack element == x then halt else continue

A program is a list: `Program = List[Instr]`.

### 1.3 VM Configuration
- `VmCfg = { stack_capacity:Int, max_steps:Int, mem_size:Int }`

### 1.4 Node
A node is:

- `Node = {`
  - `id : NodeId`
  - `state : List[Int]`             // persistent RAM snapshot (length <= mem_size required)
  - `vm : VmCfg`
  - `handlers : Map[InPort -> Program]`
  - `out_ports : List[PortId]`      // ordered mapping: OutIndex -> PortId
  - `halted : Bool`
- `}`

### 1.5 Network
- `Net = {`
  - `nodes : Map[NodeId -> Node]`
  - `routing : Map[(NodeId, PortId) -> List[(NodeId, InPort)]]`
- `}`

### 1.6 Runtime
Runtime events are *network-level*:

- `Event = { src:NodeId, out_port:PortId, payload:Value }`

Runtime state:
- `Snapshot = { net:Net, queue:FIFOQueue[(NodeId, PortId, Value)], lifetime:Int }`

A run produces:
- `Digest = { initial_snapshot:Snapshot, history:List[Step] }`

`Step` is an observable trace record containing:
- source node, destination node, in_port, payload, list of emitted `(out_port,payload)` by destination node, and resulting snapshot.

---

## 2. VM Operational Semantics (Normative)

### 2.1 VM State
VM executes a program with:
- `pc : Int` (program counter)
- `steps : Int` (number of executed instructions so far)
- `stack : Stack[Int]` (bounded by `stack_capacity`)
- `regA : Int`
- `mem : Array[Int]` length `mem_size`
- `meta_mem : Array[Int]` (constructed externally)
- `outs : List[(OutIndex, Value)]` (accumulated emissions)

### 2.2 VM Initialization
Inputs:
- `vm : VmCfg`
- `state : List[Int]`
- `meta_info : List[Int]`
- `code : Program`
- `payload : Int`
- `out_port_count : Int`

Initialize:
- if `len(state) > vm.mem_size` then FAIL.
- `mem[i] = state[i]` for `i < len(state)`, else `mem[i] = 0`.
- `meta_mem = Array(meta_info)`
- `regA = payload`
- `stack = empty`
- `pc = 0`, `steps = 0`
- `outs = []`

### 2.3 Emit Primitive
When emitting to output slot index `k`:
- require `0 <= k < out_port_count`, else FAIL.
- append `(k, regA)` to instruction-local emission list (see §2.5 ordering).

### 2.4 Normal Instruction Effects
All stack pops/peeks refer to the top of stack (failure on underflow is implementation-defined but must not silently continue).

- `Pop`: pop and discard.
- `PushConst(n)`: push n.
- `Add`: pop a; pop b; push (a+b).
- `AddMod`:
  - pop `input`
  - pop `acc`
  - let `ceil = peek(stack)`  // NOTE: not popped
  - let `sum = acc + input`
  - if `sum < ceil` then push `0` then push `sum`
    else push `1` then push `(sum - ceil)`
- `LogStack`: prints stack (no semantic effect on state/outputs).

Accumulator:
- `PushA`: push regA
- `PopA`: pop v; regA := v
- `PeekA`: regA := peek(stack)

Memory:
- `Load(i)`: bounds-check i within mem; push mem[i]
- `Store(i)`: bounds-check i; let v = peek(stack); mem[i] := v  // NOTE: store does NOT pop
- `LoadMeta(m)`: push meta_mem[Meta.to_int(m)] with bounds-check

Emission:
- `Emit`: let k = peek(stack); emit(k)   // NOTE: does NOT pop
- `EmitTo(k)`: emit(k)
- `EmitIfNonZero(k)`: if peek(stack) != 0 then emit(k)

Control instructions are handled in §2.6.

### 2.5 Output Ordering (Important)
Each executed instruction can contribute zero or more emissions.

In the reference behavior:
- `exec_instr` collects emissions for *that instruction* by prepending to a local list.
- The program loop then prepends/concats those into a global `outputs` list as:

  `outputs := outs_for_instr ++ outputs`

Net effect: `VM.exec_program` returns `outputs` in *reverse chronological order* (newest first).

(Downstream, Node and Runtime may reverse again; see §3.4 and §5.3.)

### 2.6 Control Instructions
- `Halt`: terminates immediately.
- `HaltIfEq(n,x)`:
  - let v = nth element of stack (0 = top; exact indexing must match implementation of `get_nth`)
  - if v == x then terminate else continue.
These instructions do not advance pc in the terminating case beyond what the loop defines.

### 2.7 VM Execution Loop
Repeat:
- if `steps >= vm.max_steps` then FAIL ("max_steps exceeded")
- else if `pc < 0 or pc >= len(code)` then terminate with `halted=false`
- else execute `code[pc]`:
  - apply semantics, possibly producing emissions
  - if control says Continue: pc := pc+1; steps := steps+1
  - if Halt: terminate with `halted=true`

Return:
- `final_state = Array.to_list(mem)` (length = mem_size)
- `outputs = outs` (as ordered in §2.5)
- `halted : Bool`

---

## 3. Node Semantics (Normative)

### 3.1 Meta Information
Before VM execution, build `meta_info : List[Int]` containing at least:
- node_id
- out_port_count = len(node.out_ports)
- in_port_count = size(node.handlers)
Exact layout is defined by `Meta.build` and `Meta.to_int` mapping.

### 3.2 Handling an Incoming Event
`Node.handle_event(node, port:InPort, payload:Value) -> (node', outs_actual)`
- If node.halted: return (node, []).
- Lookup handler: if `port` not in handlers -> FAIL.
- Let `out_port_count = len(node.out_ports)`.
- Run VM:
  - `(new_state, outs_sym, halted_flag) = VM.exec_program(node.vm, node.state, meta_info, code, payload, out_port_count)`
- Translate symbolic emissions:
  - Let `out_ports_array = Array(node.out_ports)`.
  - For each `(sym_idx, v)` in `outs_sym`:
    - require `0 <= sym_idx < len(out_ports_array)` else FAIL.
    - actual_id = out_ports_array[sym_idx]
    - produce `(actual_id, v)`

Return:
- `node' = node with state=new_state, halted=halted_flag`
- `outs_actual : List[(PortId, Value)]` with the same ordering as `outs_sym`.

### 3.3 VM vs Net Port Identification
- VM emits `OutIndex` (symbolic slot).
- Node maps `OutIndex k` to `PortId = out_ports[k]`.
- Network routing uses `(NodeId, PortId)` keys.

Note: the provided builder constructs `out_ports = [0..N-1]` so currently `PortId == OutIndex`, but the semantics do not require identity; only the mapping rule is normative.

### 3.4 Observable Output Ordering at Node Boundary
Because VM returns `outs_sym` newest-first (§2.5), node returns `outs_actual` newest-first as well.
Runtime later applies `List.rev` before enqueuing to restore FIFO-like ordering of emissions (see §5.3).

---

## 4. Network Semantics (Normative)

### 4.1 Connection Validity
A connection is:
- `from = (src_id:NodeId, out_port:PortId)`
- `to   = (dst_id:NodeId, in_port:InPort)`

When connecting:
- require src node exists; dst node exists.
- require `out_port` is present in `src_node.out_ports` (membership by value).
- require `in_port` exists in `dst_node.handlers`.

### 4.2 Routing Table
`routing[(src_id, out_port)]` is a list of `(dst_id, in_port)` subscribers.

The reference implementation prepends new subscriptions; therefore, subscriber order is reverse of connection order unless otherwise constrained.

### 4.3 Delivering to One Destination Node
`Net.deliver(net, dst_id, in_port, payload) -> (net', outs_actual)`
- Let dst_node = net.nodes[dst_id].
- If dst_node.halted: return (net, []).
- Else:
  - `(dst_node', outs) = Node.handle_event(dst_node, in_port, payload)`
  - Update net.nodes[dst_id] = dst_node'
  - If dst_node' is halted: remove all routing entries that point to dst_id (filter destinations).
- Return updated net and outs.

### 4.4 Subscriber Lookup
`Net.subscribers(net, src_id, out_port) -> List[(dst_id,in_port)]`
- return routing entry if present else [].

---

## 5. Runtime Semantics (Normative)

### 5.1 Queue Elements
Internal queue elements are triples:
- `(src_id, out_port, payload)` corresponding to `Event`.

### 5.2 Enqueue
`enqueue(ev, snap)`:
- if `snap.lifetime <= 0` then FAIL ("immortal activity detected")
- push `(ev.src, ev.out_port, ev.payload)` to FIFO queue
- decrement lifetime by 1

### 5.3 Deliver One Runtime Event
Given event `ev = {src, out_port, payload}`:
1. `subs = Net.subscribers(snap.net, ev.src, ev.out_port)`
2. For each `(dst_id, in_port)` in `subs` (left-to-right):
   - `(net_after, outs) = Net.deliver(snap.net, dst_id, in_port, ev.payload)`
   - update snapshot net = net_after
   - let `outs_chrono = reverse(outs)`  // IMPORTANT: restores chronological order within outs
   - for each `(out_p, v)` in `outs_chrono`:
       enqueue `{src=dst_id, out_port=out_p, payload=v}`
   - record a `Step` capturing src/dst/in_port/payload/emitted=outs_chrono/snapshot=updated_snapshot
3. Return updated snapshot and list of produced Steps (newest first or as accumulated; exact history ordering is defined by the runtime loop).

### 5.4 One Step
If queue empty: return None.
Else dequeue head `(src,out_port,payload)` and process via §5.3, returning updated snapshot.

### 5.5 Avalanche
Repeatedly apply One Step until the queue is empty (or failure due to lifetime).

### 5.6 Scheduled Run
Given a schedule `List[Event]`:
For each scheduled event in order:
- enqueue it
- run avalanche
Stop early if an optional predicate `stop_when(snapshot)` becomes true.

---

## 6. Builder Conventions (Non-Normative, Current Implementation)

NodeBuilder:
- assigns incoming ports as 0,1,2,... in order of `add_handler`
- assigns outgoing ports as 0,1,2,... in order of `add_out_port`
- assigns node ids as 1,2,3,... (0 reserved)

NetBuilder:
- adds nodes to net
- connects using `(src_id, out_port)` → `(dst_id, in_port)`

These conventions explain why `PortId == OutIndex` in the current implementation, but they are not required by the core semantics.

---

## 7. Conformance Notes (What Must Match)

A conforming reimplementation must match:
- VM instruction semantics including non-pop `Store`, non-pop `Emit`, and `AddMod` peek behavior.
- VM termination semantics: pc out of bounds terminates with `halted=false`; `max_steps` triggers failure.
- Emission ordering: VM returns newest-first; runtime reverses before enqueueing.
- Node translation: `OutIndex -> out_ports[k]` with bounds checks.
- Network delivery + routing cleanup when a node halts.
- Runtime lifetime decrement happens on enqueue (not on dequeue).
