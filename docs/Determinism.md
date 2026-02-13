# 7. Determinism & Ordering Guarantees

Determinism is not an accidental property of Emu.  
It is a deliberate design guarantee.

This chapter makes explicit what ordering rules exist and why execution is fully reproducible.

---

## 7.1 What Determinism Means in Emu

Given:

- The same initial node states
- The same static topology
- The same injected external events (in the same order)

Emu guarantees:

- The same sequence of transitions
- The same intermediate snapshots
- The same final state
- The same emitted events

There are no alternate execution paths.

There is exactly one unfolding.

---

## 7.2 Sources of Determinism

Determinism arises from five structural constraints:

### 1. Static Topology
Connections between ports never change during execution.

### 2. FIFO Event Queue
Events are processed strictly in first-in, first-out order.

### 3. Deterministic Subscriber Resolution
Subscribers for a given `(node, out_port)` are resolved in a fixed, deterministic order.

### 4. Deterministic VM Semantics
Given identical input and local state, a handler produces identical state updates and emitted events.

### 5. Absence of Concurrency
There are no threads, no parallel execution, and no scheduling interleavings.

These properties eliminate nondeterministic behavior.

---

## 7.3 Event Ordering Rules

The ordering of events is strictly defined.

### Rule 1 — Queue Discipline

- Events are dequeued from the front.
- Emitted events are appended to the back.

No event can overtake another.

---

### Rule 2 — Subscriber Processing Order

When an event has multiple subscribers:

- Subscribers are processed in deterministic order.
- Each subscriber’s handler executes fully before the next begins.

There is no interleaving between handlers.

---

### Rule 3 — Emission Order

Within a single handler execution:

- Events are emitted in the order defined by the VM program.
- They are appended to the queue in that same order.

If multiple subscribers emit events:

- The events from the first subscriber are appended first.
- Then the events from the second subscriber.
- And so on.

The resulting queue order is fully determined.

---

## 7.4 Cascades and Nested Reactions

Emu does not evaluate recursively.

It evaluates iteratively via the global queue.

If a handler emits events that trigger further emissions:

- Those new events are appended.
- They are processed later in FIFO order.

This ensures that causal chains unfold in a stable and predictable sequence.

---

## 7.5 Node Halting and Routing Pruning

A node may enter a halted state during handler execution.

Once halted:

- It no longer processes incoming events.
- Future events addressed to it are ignored.

Additionally, routing entries pointing to the halted node may be pruned.

This pruning is deterministic and permanent.

Halting affects future transitions but does not retroactively alter history.

---

## 7.6 No Hidden Interleavings

Unlike actor systems or concurrent runtimes:

- There is no scheduler deciding execution order.
- There are no race conditions.
- There are no alternate interleavings.

At every step, exactly one event is processed.

The execution order is uniquely determined.

---

## 7.7 Reproducibility Guarantee

Because of these rules:

- Test results are stable.
- Debugging is repeatable.
- Experiments are reliable.
- Snapshots can be compared across runs.

Two executions with identical inputs will produce identical histories.

This is a structural guarantee, not a probabilistic one.

---

## 7.8 What Emu Does Not Guarantee

Emu does not model:

- Real-time ordering
- Distributed scheduling variability
- Network delays
- Concurrency races

It guarantees deterministic causal evaluation — not physical realism.

---

## 7.9 Summary

Emu enforces strict ordering rules:

- FIFO event processing
- Deterministic subscriber resolution
- Deterministic VM execution
- Sequential handler evaluation
- No concurrency

These constraints ensure that the causal evolution of the network is fully predictable and reproducible.

Determinism is not an implementation detail.

It is a foundational property of the engine.
