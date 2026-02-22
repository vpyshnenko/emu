# Emu Causality Theory  
## Chapter 10 — Definition of a Causal Processor

Before introducing a taxonomy of causal processors, we define the term itself.

---

## 1. Informal Definition

A **causal processor** is a system that:

- Receives events,
- Applies state transitions,
- Produces new events as consequences,
- And unfolds these consequences according to a defined scheduling discipline.

The defining feature is:

> All observable behavior arises exclusively from causal propagation of events.

There are no spontaneous state transitions.

---

## 2. Formal Definition

A causal processor is a tuple:

    CP = (Σ, E, δ, F, S)

where:

- Σ is the set of global states.
- E is the set of events.
- δ is a deterministic or nondeterministic transition function:

      δ : Σ × E → Σ × List(E)

- F is a frontier structure (event container).
- S is a selection policy determining which event from F is processed next.

---

## 3. Operational Semantics

Execution proceeds as follows:

1. Inject an initial event into the frontier F.
2. While F is not empty:
   - Select an event e according to S.
   - Apply δ to update state and obtain new events.
   - Insert emitted events into F according to the frontier discipline.

Formally:

    (σ, F) → (σ', F')

where:

- One event is removed from F.
- δ produces zero or more new events.
- These are inserted into F.

---

## 4. Essential Properties

A system qualifies as a causal processor if:

### 4.1 Causal Closure

Every event processed is either:

- Injected externally, or
- Produced by a previous event.

There are no spontaneous events.

---

### 4.2 Local Transition Semantics

State updates occur only during event processing.

---

### 4.3 Event-Driven Evolution

Global evolution is entirely determined by successive event deliveries.

There is no autonomous time-based evolution.

---

## 5. Deterministic vs Non-Deterministic

A causal processor is **deterministic** if:

- δ is deterministic,
- Selection policy S is deterministic.

Otherwise it is nondeterministic.

Emu is deterministic.

---

## 6. Frontier Discipline

The nature of F and S determines the processor’s kind:

- FIFO frontier → breadth-first layering
- LIFO frontier → depth-first behavior
- Priority frontier → ordered causality
- Multiple frontiers → fragmented horizon

Thus the frontier structure defines the geometry of causal expansion.

---

## 7. Injection Semantics

A causal processor may restrict injection to:

- Quiescent states only (single-wave semantics), or
- Arbitrary states (multi-wave semantics).

This distinction influences generational structure.

---

## 8. Emu as a Causal Processor

Emu satisfies:

- Deterministic δ
- Global FIFO frontier
- Injection only at quiescence
- Run-to-completion semantics

Therefore Emu is:

> A deterministic, single-frontier, breadth-first causal processor.

This places it in the class of first-kind causal processors.

---

## 9. Summary

A causal processor is a stateful event-driven system whose evolution is entirely determined by causal propagation of events through a frontier governed by a selection discipline.

The frontier and selection policy define the processor’s causal geometry.

This definition provides the foundation for classifying causal processors into structural kinds.