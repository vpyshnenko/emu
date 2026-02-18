# STEP 11 — Causal Closure

This section defines the Causal Closure property of Emu.

Causal closure states that every event and every state change
occurring during execution is causally derived from
a finite sequence of external injections.

There are no spontaneous events.

---

## 1. Events and Causality

An emitted value has the form:

    e = (src, op, v)

During execution, events appear in the pending frontier E
and are processed by the Deq operation.

Define the causal parent relation:

An emission e₂ is causally derived from emission e₁
if e₂ is produced during the delivery expansion
of e₁ or during a chain of expansions rooted in e₁.

Formally, define relation:

    e₁ ≺ e₂

if e₂ is produced during Deq(e₁)
or via transitive application of Deq
originating from e₁.

The transitive closure of ≺ defines the causal ancestry.

---

## 2. Causal Roots

The only primitive source of new activity is external injection.

An injected emission e₀ is a causal root.

Every other emission appearing during execution
must be causally descended from:

- A causal root (injected emission), or
- An emission present in the initial Snapshot.

There are no other sources of emissions.

---

## 3. Causal Closure Theorem

For any reachable Snapshot during execution:

For every emission e in its history,
there exists a finite sequence:

    e₀ ≺ e₁ ≺ … ≺ eₖ = e

where e₀ is either:

- An injected emission, or
- An emission present in the initial Snapshot.

Thus:

All events are causally rooted.

---

## 4. State Causality

State changes are also causally closed.

A state update to node n occurs only during delivery of an emission.

Therefore:

For any state σ(n) at step k,
its value is the result of applying a finite sequence of δ transitions,
each triggered by causally rooted emissions.

No state mutation occurs outside causal event delivery.

---

## 5. Avalanche-Level Causality

Under run-to-completion semantics:

Execution decomposes into avalanche segments:

    S₀
      ↦ e₁ →* S₁
      ↦ e₂ →* S₂
      ...

Within each avalanche:

- All emissions are causally descended from exactly one injected emission.
- No emission from another injection appears.
- The causal graph forms a finite rooted tree (or forest if multiple initial emissions are present).

Thus, avalanches are causally isolated.

---

## 6. Absence of Spontaneous Transitions

Causal closure implies:

- No node can emit without receiving an event.
- No emission can appear without a predecessor.
- No state can change without a triggering emission.

This property follows from strict reactivity:

Internal transitions are defined only when E ≠ [].

---

## 7. Deterministic Causal Structure

Because the transition system is deterministic:

- The causal graph induced by a given injection sequence is unique.
- The ancestry relation ≺ is uniquely determined.
- The trace fully determines the causal structure.

There is no ambiguity in causal origin.

---

## 8. Structural Consequences

Causal closure guarantees:

1. Finite ancestry for every event.
2. No hidden channels of influence.
3. No spontaneous state mutation.
4. Clean partitioning of execution into causally independent avalanches.
5. Deterministic trace reconstruction of causal graphs.

---

## 9. Conceptual Summary

Emu is causally closed.

All computation is event-driven.
All events are causally rooted.
All state transitions are causally justified.

There is no spontaneous behavior.

Causal closure is a fundamental safety property
of the Emu execution model.
