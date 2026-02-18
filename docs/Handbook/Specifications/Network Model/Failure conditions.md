# STEP 7 — Failure Conditions

This section defines the failure semantics of the
Deterministic Network of Reactive State Machines.

Failure behavior must be specified explicitly so that
independent implementations cannot diverge silently.

Failure is modeled as transition to a distinguished state:

    ⊥   (Failure)

Failure is terminal: no further transitions are defined from ⊥.

All failure conditions below are normative.

---

## 1. Invalid Port Conditions

### 1.1 Invalid Injection

An externally injected emission

    (src, op, v)

is invalid if:

- src ∉ Nodes, or
- op ∉ OutPorts(src).

If an invalid injection is attempted, the system transitions to ⊥.

Formally:

If injection preconditions are violated:

    (σ, []) ↦ ⊥

Injection is not silently ignored.

---

### 1.2 Invalid Routing Target

Routing relation R must satisfy:

For every

    ((src, op), (dst, ip)) ∈ R

- dst ∈ Nodes
- ip ∈ InPorts(dst)

If during delivery an emission expands to a
(dst, ip) that is not valid for the current network,
execution transitions to ⊥.

Invalid routing is not silently skipped.

---

## 2. Delivery to Halted Node

A node may enter a halted state.

A halted node:

- Does not execute its transition function.
- Produces no emissions.

If an emission is delivered to a halted node:

- The delivery is ignored.
- The global state σ remains unchanged.
- No failure occurs.

Formally:

If σ(dst) is halted, then delivery produces:

    (σ, E) → (σ, E')

with no state change and no new emissions.

Routing structure R is not modified.

---

## 3. Step Bound Exceeded

An implementation may enforce a finite bound on:

- Maximum number of internal steps per avalanche, or
- Maximum total steps for execution.

Let B be a defined step bound.

If during execution the number of internal transitions
since the last injection exceeds B,
execution transitions to ⊥.

Formally:

If steps ≥ B during an avalanche:

    (σ, E) → ⊥

This bound is part of the execution environment,
not the abstract transition relation,
but its failure mode must be consistent across implementations.

---

## 4. Infinite Cascade (Divergence)

An avalanche diverges if there exists an infinite sequence:

    S₁ → S₂ → S₃ → ...

In the abstract model, divergence is not a failure;
it is non-termination.

However, implementations cannot realize infinite execution.

Therefore:

If divergence is detected or prevented by a finite bound,
the implementation must transition to ⊥
rather than silently truncate execution.

No partial stabilization is permitted.

---

## 5. Structural Consistency Violations

The following structural violations produce failure:

- Duplicate NodeId definitions.
- Invalid routing references.
- Inconsistent port declarations.
- Transition function undefined for a valid input.

Such violations transition immediately to ⊥.

---

## 6. Failure Properties

Failure has the following properties:

1. Terminal:  
   No transitions are defined from ⊥.

2. Deterministic:  
   Given the same initial Snapshot and injection sequence,
   failure occurs at the same step.

3. Observable:  
   Failure state is externally distinguishable.

4. Non-recoverable:  
   Recovery requires reinitialization of the system.

---

## 7. Summary of Failure Triggers

Execution transitions to ⊥ in the following cases:

1. Invalid external injection.
2. Invalid routing reference.
3. Structural inconsistency.
4. Step bound exceeded.
5. Divergence prevented by bound enforcement.

Delivery to halted nodes is not a failure.

---

This specification ensures that:

- Invalid configurations do not produce silent behavior differences.
- Resource exhaustion produces explicit failure.
- Divergence is not mistaken for successful stabilization.
- Independent implementations remain observationally aligned.
