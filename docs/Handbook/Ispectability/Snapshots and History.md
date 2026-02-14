# 8. Snapshots and History
## Thinking in Time-Free Systems

Emu does not model physical time.

There are no timestamps.
There are no delays.
There is no global clock.

Yet Emu preserves something more important for reasoning:

It preserves history.

---

## 8.1 No Time, Only Transitions

In many systems, behavior is described in terms of time:

- At time T1, this happened.
- After 5ms, that happened.
- Eventually, something stabilized.

In Emu, there is no notion of time.

Instead, there is only a sequence of transitions:

C0 -> C1 -> C2 -> C3 -> ...

Each step represents a causal transformation of the global configuration.

The system evolves not because time passes,
but because events are processed.

Time is replaced by order.

---

## 8.2 What Is a Snapshot?

A snapshot is a complete record of the system state at a given transition.

It includes:

- The state of every node
- The halted status of nodes
- The contents of the event queue
- The static topology (implicitly)

A snapshot does not approximate the system.

It is the system at that step.

---

## 8.3 History as a First-Class Concept

Each transition produces a new configuration.

The sequence of configurations forms a history:

C0, C1, C2, ..., Ck

This history is:

- Deterministic
- Reproducible
- Inspectable

You can:

- Examine intermediate states
- Trace causal chains
- Analyze emitted values
- Reconstruct why something happened

History is not lost between steps.
It is preserved.

---

## 8.4 Thinking Without Time

In Emu, reasoning shifts from:

"When did this happen?"

to:

"What caused this?"

Instead of timestamps, you analyze:

- Which event triggered which handler
- Which state change caused which emission
- Which cascade led to which outcome

This way of thinking emphasizes causality over chronology.

---

## 8.5 Step-by-Step Inspection

The step-through execution model allows you to:

- Advance one transition at a time
- Observe state evolution
- Pause and inspect configuration
- Compare snapshots
- Replay from the beginning

Because execution is deterministic:

- The same inputs always produce the same history.
- You can rerun scenarios confidently.
- Debugging becomes systematic rather than speculative.

---

## 8.6 Snapshots vs Logging

Snapshots are not logs.

Logs record observations.
Snapshots record state.

A snapshot allows full reconstruction of the system at a given step.

This distinction is important:

- Logs show what happened.
- Snapshots show what the system was.

Emu treats state history as a primary artifact.

---

## 8.7 Branching and Exploration

Because history is preserved and execution is deterministic, you can:

- Restart from initial state
- Inject alternative events
- Compare different evolutions
- Explore "what-if" scenarios

This makes Emu suitable not only for execution,
but for exploration.

---

## 8.8 A Different Mental Model

In time-driven systems:

- Time advances.
- State reacts to time.

In Emu:

- Events advance.
- State reacts to events.

Snapshots provide a structured way to observe this evolution.

Understanding comes from examining transitions,
not measuring time.

---

## 8.9 Summary

Emu is a time-free, transition-based system.

Behavior unfolds through causal steps.
Each step produces a complete, immutable snapshot.
The sequence of snapshots forms the system's history.

By preserving history instead of modeling time,
Emu enables deterministic, inspectable reasoning about dynamic systems.
