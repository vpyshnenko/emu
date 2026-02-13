# 11. Limits of the Model

Emu is intentionally minimal.

It models deterministic causal propagation in networks of finite-state machines.
It does not attempt to model every aspect of real distributed or concurrent systems.

Understanding these limits is essential for using Emu correctly.

---

## 11.1 No Physical Time

Emu has no notion of:

- real time
- logical clocks
- timeouts
- delays
- jitter
- latency

Events are processed in FIFO order, not based on timestamps.

You cannot model:

- network delays
- timeout-based protocols
- time-driven scheduling
- real-time guarantees

If timing matters to your system, Emu models only the logical structure, not the temporal behavior.

---

## 11.2 No Concurrency

Emu executes sequentially.

There are:

- no threads
- no parallel handlers
- no race conditions
- no interleavings

Only one event is processed at a time.

This means Emu does not model:

- thread contention
- data races
- scheduling variability
- concurrent execution anomalies

It isolates pure causal logic by removing concurrency entirely.

---

## 11.3 No Nondeterminism

Emu is fully deterministic.

There is:

- no randomness
- no nondeterministic scheduling
- no alternative execution paths

If your system relies on:

- probabilistic behavior
- randomized protocols
- nondeterministic transitions

You must model randomness explicitly within node logic.

---

## 11.4 Static Topology

Connections between nodes are fixed during execution.

Emu does not support:

- dynamic rewiring
- node creation or destruction
- topology mutation

If your system requires structural evolution, that must be encoded manually.

---

## 11.5 Bounded Execution

Execution continues until:

- the event queue is empty, or
- a configured step limit is reached.

Emu does not:

- automatically detect livelock
- prove termination
- enforce global invariants

It executes exactly what you define.

---

## 11.6 No Resource Modeling

Emu does not simulate:

- CPU load
- memory contention
- bandwidth limits
- hardware constraints
- physical failures

It models logical state transitions only.

---

## 11.7 What Emu Is Good For

Despite these limits, Emu is powerful for:

- validating protocol logic
- analyzing causal chains
- exploring feedback behavior
- studying stabilization
- prototyping distributed algorithms
- teaching dynamic systems

It reveals structural correctness,
not performance characteristics.

---

## 11.8 A Clear Boundary

Emu answers questions like:

- What happens if this event occurs?
- Does this state machine stabilize?
- Does this topology produce oscillation?
- Are there unintended feedback loops?
- Is the causal structure coherent?

It does not answer:

- How long does it take?
- What happens under packet loss?
- How does scheduling affect behavior?
- What is the throughput under load?

---

## 11.9 Summary

Emu models deterministic causal computation.

It intentionally excludes:

- time
- concurrency
- nondeterminism
- dynamic topology
- physical resource constraints

These are not omissions.
They are design boundaries.

Within those boundaries, Emu provides clarity, reproducibility, and precise insight into the logical structure of dynamic systems.
