# Emu Abstract Machine (EAM)

## 1. Parameters (Static)

### 1.1 Program / Node parameters
Each node `n` has fixed components:
- `id(n) : NodeId`
- `vmcfg(n) = {stack_capacity, max_steps, mem_size}`
- `handlers(n) : InPort ↦ Program`
- `out_ports(n) : List[PortId]`   // length = OutPortCount(n)

### 1.2 Network routing
A routing table:
- `R : (NodeId × PortId) ↦ List[(NodeId × InPort)]`

---

## 2. Machine State

An EAM global state is:

- `Σ = ⟨N, R, Q, L, H⟩`

where:
- `N : NodeId ↦ NodeState`
- `NodeState = ⟨halted:Bool, state:List[Int]⟩`
- `R` is routing (static unless pruning halted destinations; see rule NET-PRUNE)
- `Q` is a FIFO queue of network events `(src:NodeId, out_port:PortId, payload:Int)`
- `L : Int` is lifetime budget
- `H` is a trace/history sequence (optional)

---

## 3. Derived Functions

### 3.1 Out port count
- `outCount(n) = len(out_ports(n))`

### 3.2 Meta memory builder
- `meta(n) : List[Int] = Meta.build(node_id=id(n), out_port_count=outCount(n), in_port_count=|dom(handlers(n))|)`
(Exact layout is delegated to the Meta module but is deterministic.)

### 3.3 VM execution
A partial function (may fail) that corresponds to `Vm.exec_program`:

- `VMExec(n, prog, payload, stateList) = ⟨newStateList, outsSym, haltedFlag⟩`

where:
- `newStateList : List[Int]` length = `mem_size`
- `outsSym : List[(OutIndex, Value)]` (newest-first as returned by your VM)
- `haltedFlag : Bool` (`true` if Halt/HaltIfEq triggered; `false` if pc out of bounds)

Failures:
- state longer than mem_size
- max_steps exceeded
- out-of-bounds memory/meta access
- invalid emit index

### 3.4 Node handler (one incoming delivery)
This corresponds to `Node.handle_event`:

`Handle(nid, in_port, payload, N)` returns:
- updated node state `NodeState'`
- list of physical emissions `outsPhys : List[(PortId, Value)]` (newest-first)

Definition (if node not halted):

1. `prog = handlers(nid)[in_port]` else fail
2. `⟨newState, outsSym, haltedFlag⟩ = VMExec(nid, prog, payload, N[nid].state)`
3. translate each `(k,v)` in `outsSym` to `(out_ports(nid)[k], v)` with bounds check
4. return `NodeState' = ⟨haltedFlag, newState⟩` and translated outs

If node halted already: returns unchanged node state and `[]`.

### 3.5 Expand emissions to deliveries
Given a physical emission `(src_id, out_port, v)`:
- `Subs = R[(src_id, out_port)]` default `[]`
- produces delivered events `[(dst, in_port, v) for (dst,in_port) in Subs]`

Note: delivery invokes destination node handler; it does not enqueue the delivered event (delivery is immediate in your runtime), but emissions produced by the destination are enqueued.

---

## 4. Transition Relation (Small-Step)

We write:

- `Σ → Σ'`

A single abstract-machine step corresponds to `Runtime.step` handling one queued event and delivering it to all subscribers (fold-left), enqueuing resulting emissions.

### Rule STEP (dequeue one event and process)

If `Q = (src, outp, payload) :: Qrest` then:

1) Dequeue:
- `Q := Qrest`

2) For each subscriber `(dst, in_port)` in `R[(src,outp)]` in list order, perform DELIVERY (see below), threading the evolving network state and queue.

Result is `Σ' = ⟨N', R', Q', L', H'⟩`.

If `Q` is empty: machine is terminal (no transition).

---

### Rule DELIVERY (deliver to one subscriber)
Given current intermediate state `⟨N, R, Q, L, H⟩` and one subscriber `(dst,in_port)`:

If `N[dst].halted = true`:
- no change (skip), no outputs.

Else:

1) Node compute:
- `⟨NodeState', outsPhys⟩ = Handle(dst, in_port, payload, N)`

2) Update node:
- `N := N[dst ↦ NodeState']`

3) If `NodeState'.halted = true`, apply NET-PRUNE:
- remove every destination pair whose `dst == dst_id` from all routing lists.
(Equivalently: `R := filterDest(R, dst_id)`.)

4) Enqueue node’s outputs:
Your runtime reverses node outputs before enqueue:
- let `outsChrono = reverse(outsPhys)`  // restore chronological order
- for each `(outp2, v2)` in `outsChrono` in order:
  - apply ENQUEUE rule

5) Emit trace step entry into `H` (optional, but deterministic if present).

---

### Rule ENQUEUE (lifetime-based enqueue)
To enqueue `(src2, outp2, v2)`:

- if `L <= 0` then fail
- `Q := Q ++ [(src2, outp2, v2)]`  // FIFO append
- `L := L - 1`

Note: lifetime is decremented on enqueue (including schedule injection), not on dequeue.

---

## 5. Observational Behavior

### 5.1 Port identification
- VM emits `OutIndex k`.
- Node resolves `k` to `PortId out_ports[ k ]`.
- Network routes using `(NodeId, PortId)` keys.

### 5.2 Ordering guarantees (as implemented)
- VM returns emissions newest-first.
- Node keeps that ordering.
- Runtime reverses per-delivery before enqueue so emissions are enqueued in the program’s chronological emission order.
- Subscriber list order affects delivery order (and thus overall behavior) because deliveries are sequential and can mutate node states and enqueue events.

### 5.3 Determinism
Given:
- fixed initial `Σ0`
- fixed ordering of subscriber lists and queue discipline
Emu is deterministic (modulo `LogStack` IO).

---

## 6. Initialization and Run

### 6.1 Initial state
- `N` from constructed nodes’ `(halted=false, state=initial_state)`
- `R` from connections
- `Q = []`
- `L = lifespan`
- `H = []`

### 6.2 Schedule execution
For each scheduled event `ev = (src,outp,payload)`:
- apply ENQUEUE to add `ev` to `Q`
- repeatedly apply STEP until `Q` is empty (avalanche)
- optionally stop if predicate `stop_when(Σ)` becomes true

---

## 7. Failure Conditions (Must Match)
The machine fails (raises error) on:
- lifetime exhausted on enqueue
- VM max_steps exceeded
- VM memory/meta index out of bounds
- VM emit index out of bounds
- delivering to missing node or handler port
- translating an emitted OutIndex outside out_ports length
