# Emu Causality Theory  
## Chapter 11 — Spiral Trajectory and Discrete “Quantum Jumps” of a First-Kind Causal Processor

The circular embedding of generations (Chapter 9) describes the *geometry of causal structure*.

This chapter describes the *geometry of execution*.

When embedded in radial form, the execution order of a first-kind causal processor traces a discrete outward spiral, advancing by stepwise radial transitions between generations.

---

## 1. Preliminaries

Let:

    Gₖ = set of events of generation k

Let events within Gₖ be ordered according to FIFO delivery order.

Embed each generation on a circle of radius:

    rₖ

with:

    rₖ₊₁ > rₖ

Events within Gₖ are arranged along the circle in delivery order.

---

## 2. Execution Path

Let:

    d₀, d₁, d₂, ...

be the sequence of delivered events during an avalanche.

From the Monotone Generation Theorem:

    gen(d_{t+1}) ≥ gen(d_t)

and all events of generation k are delivered before any event of generation k+1.

Thus execution proceeds as:

- Traverse all events in G₀
- Then all events in G₁
- Then all events in G₂
- And so on

In the radial embedding:

- Traversing Gₖ corresponds to moving along orbit rₖ.
- Transition from Gₖ to Gₖ₊₁ corresponds to radial advancement.

---

## 3. Discrete Spiral Structure

Connecting successive delivered events in the embedding yields:

- Circular motion within each orbit,
- Followed by discrete outward radial transitions.

Thus the execution trajectory is:

> A piecewise circular path with outward radial increments.

In the limit of large generations, this resembles an outward discrete spiral.

---

## 4. Angular and Radial Components

The spiral has two independent components:

### 4.1 Angular Component

Movement along orbit rₖ corresponds to FIFO ordering within generation Gₖ.

This reflects sequential consumption of that generation.

---

### 4.2 Radial Component

The radial coordinate increases only when the current generation is exhausted.

Depth increases in integer steps.

No intermediate depth is visited.

---

## 5. The Discrete “Quantum Jump” Analogy

After finishing one orbit, the processor “jumps” to the next.

This is exactly what the Monotone Generation Theorem guarantees.

The jump occurs when:

    Gₖ is exhausted

At that moment:

- The frontier minimum generation increases.
- The radial layer shifts from rₖ to rₖ₊₁.
- The causal horizon advances outward.

This transition is discrete:

- There is no partial depth advancement.
- Generation index increases by exactly one.
- The processor does not deliver any event from generation k+1 until generation k is fully drained.

Therefore, the analogy to a “quantum jump” is structurally reasonable:

- Depth advances in discrete integer units.
- The system exhibits stepwise layer transitions rather than continuous depth drift.

This is a purely combinatorial phenomenon induced by FIFO breadth-first evaluation, not a physical quantum effect.

---

## 6. Relation to the Horizon Model

During traversal of orbit rₖ:

- The past accumulates behind the processor (inner disk).
- The remaining part of Gₖ remains in the frontier.
- Gₖ₊₁ is being constructed in the outer orbit.

When the jump occurs (Gₖ exhausted):

- The remaining frontier becomes exactly the next generation.
- The “near future” collapses to a single layer before rebuilding again.

Thus each jump corresponds to a discrete advancement of the event horizon.

---

## 7. Stability and Spiral Geometry

Let:

    λₖ = |Gₖ₊₁| / |Gₖ|

Then:

- λₖ > 1 → outward spiral spacing increases.
- λₖ = 1 → uniform spiral spacing.
- λₖ < 1 → shrinking spiral.
- λₖ → 0 → termination.

Supercritical avalanches correspond to accelerating radial growth.

---

## 8. Spiral as Signature of First-Kind Processors

The spiral + discrete jump structure depends on:

- Single global FIFO frontier.
- Strict generation monotonicity.
- No interleaving of layers (layer integrity).

If frontier discipline changes:

- LIFO → deep branching spikes rather than layer jumps.
- Multiple frontiers → fragmented trajectories.
- Nondeterministic selection → irregular, non-layered paths.

Thus the discrete spiral with stepwise layer jumps is a structural signature of first-kind causal processors.

---

## 9. Summary

In the radial embedding of generations, the execution of a first-kind causal processor forms a discrete outward spiral:

- Circular traversal within each generation layer,
- Followed by a discrete “jump” to the next layer when the current generation is exhausted.

These jumps correspond to monotone generation advancement and discrete horizon shifts, providing a geometric visualization of strict breadth-first causal propagation.