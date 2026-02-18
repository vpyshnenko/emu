# STEP 8 — State Invariants

This section defines the safety invariants of a
Deterministic Network of Reactive State Machines.

State invariants are properties that must hold
for every reachable Snapshot during execution,
including intermediate steps within an avalanche.

They define safety guarantees of the model.

Let a Snapshot be:

    S = (σ, E)

where:

- σ : NodeId → State
- E ∈ List(EmittedValue)

An Emitted Value has the form:

    (src, op, v)

---

## 1. Reachability

All invariants below apply to every Snapshot S
reachable from an initial well-formed Snapshot
via the transition relations:

- Internal step  (σ, E) → (σ', E')
- External injection  (σ, []) ↦ (σ, [e])

If an invariant is violated, execution transitions to ⊥.

---

## 2. Node Existence Invariant

Every event in the pending frontier references an existing node.

For all (src, op, v) ∈ E:

    src ∈ Nodes

This ensures that no event can be dequeued
for a non-existent source node.

---

## 3. Output Port Validity Invariant

Every event in the pending frontier references
a valid output port of its source node.

For all (src, op, v) ∈ E:

    op ∈ OutPorts(src)

This guarantees that every emitted value
is structurally valid within the network.

---

## 4. Routing Target Validity Invariant

For all routing entries:

    ((src, op), (dst, ip)) ∈ R

the following must hold:

    src ∈ Nodes
    dst ∈ Nodes
    op ∈ OutPorts(src)
    ip ∈ InPorts(dst)

Thus, delivery never targets a non-existent node
or an invalid input port.

---

## 5. Delivery Safety Invariant

During internal expansion of an emission:

If (dst, ip) ∈ Subs(src, op),

then:

    dst ∈ Nodes
    ip ∈ InPorts(dst)

Therefore, no delivery is performed
to a non-existent node or invalid port.

---

## 6. Frontier Validity Invariant

The pending frontier contains only valid network events.

Formally:

For every (src, op, v) ∈ E:

    src ∈ Nodes
    op ∈ OutPorts(src)

and v ∈ Value.

Thus, the frontier never contains malformed emissions.

---

## 7. Lifetime Monotonicity (If Lifetime Is Modeled)

If a Snapshot includes a lifetime parameter L ∈ ℕ,
used as a resource bound,

then for every transition:

    L' ≤ L

and for any internal step:

    L' < L

Thus, lifetime decreases monotonically
and never increases.

If L reaches zero, execution transitions to ⊥.

This invariant ensures bounded execution
when lifetime is part of the model.

---

## 8. Deterministic Scheduling Invariant

For any Snapshot (σ, E) with E ≠ [],

- The head of E is uniquely defined.
- Subscriber ordering for (src, op) is uniquely defined.
- The next internal transition is uniquely determined.

Thus, the system has no internal nondeterminism.

---

## 9. Avalanche Isolation Invariant

During execution of an avalanche induced by injection e:

- No new external injection is permitted.
- All emissions in E are causally derived
  from the same injection root.

Therefore, the frontier never mixes emissions
from distinct external injections.

---

## 10. Preservation

All invariants above are preserved by:

- Internal transitions.
- Valid external injection.
- Stabilization of avalanches.

If the initial Snapshot satisfies all invariants,
and all injections are well-formed,
then every reachable Snapshot satisfies them.

---

## 11. Summary

The safety invariants ensure:

- Structural integrity of routing.
- Validity of all queued emissions.
- Validity of all deliveries.
- Deterministic scheduling.
- Proper resource-bound behavior (if modeled).
- Isolation of avalanches.

These invariants define the safety properties
of the Emu execution model.
