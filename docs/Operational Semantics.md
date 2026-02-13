# 6. Operational Semantics

This chapter defines the precise transition rules that govern how an Emu system evolves.

While the computational model defines the entities of the system, the operational semantics defines how the system moves from one state to the next.

---

## 6.1 Global Configuration

A global configuration of an Emu system consists of:

- The local state of all nodes
- The halted status of each node
- The global event queue
- The static topology

This configuration completely determines future evolution.

---

## 6.2 External Event Injection

Computation begins when an external event is injected.

An injected event is appended to the end of the global FIFO queue.

No other changes occur at injection time.

---

## 6.3 The Main Transition Rule

If the event queue is not empty, one transition step proceeds as follows:

### Step 1 — Dequeue

Remove the first event from the queue.

Let the event be:

- `(src_node, out_port, payload)`

---

### Step 2 — Resolve Subscribers

Using the static topology, determine all subscribed input ports:

- For each connection `(dst_node, in_port)` subscribed to `(src_node, out_port)`.

If there are no subscribers, the event is discarded.

---

### Step 3 — Deliver to Each Subscriber

For each subscribed `(dst_node, in_port)`:

1. If the destination node is halted, skip it.
2. Otherwise:
   - Execute the corresponding handler program on the node’s VM.
   - Provide the payload as input.
   - Allow the VM to:
     - Read and update local state
     - Emit zero or more events
     - Halt the node

---

### Step 4 — Enqueue Emitted Events

All events emitted by handler execution are appended to the end of the global FIFO queue.

If multiple subscribers emit events, their emitted events are appended in deterministic order.

---

### Step 5 — Record Snapshot

After processing the dequeued event and all its subscriber deliveries:

- The updated global configuration may be recorded as an immutable snapshot.

Snapshots capture:

- All node states
- Halted status
- Remaining event queue

---

## 6.4 Iteration

The system repeats the Main Transition Rule until:

- The event queue becomes empty, or
- A global stopping condition is reached.

---

## 6.5 Quiescence

The system is in a quiescent state when:

- The event queue is empty.

No further transitions are possible.

Quiescence does not imply stability in a formal sense.  
It only indicates that no pending reactions remain.

---

## 6.6 Node Halting

A node may enter a halted state during handler execution.

If a node is halted:

- It no longer processes incoming events.
- Events addressed to it are ignored.
- It may optionally trigger pruning of routing entries (implementation detail).

Halting affects future transitions but does not rewind history.

---

## 6.7 Deterministic Ordering

Determinism is guaranteed by the following rules:

1. The event queue is FIFO.
2. Topology is static.
3. Subscriber resolution order is deterministic.
4. VM execution is deterministic.
5. Emitted events are appended in defined order.
6. There is no concurrency.

Given identical initial conditions and injected events, the entire transition sequence is identical.

---

## 6.8 One-Step Summary

Each operational step can be summarized as:

Dequeue → Deliver → Execute → Emit → Enqueue → Record

This loop continues until no events remain.

---

## 6.9 Conceptual View

Operationally, Emu defines a transition relation:

