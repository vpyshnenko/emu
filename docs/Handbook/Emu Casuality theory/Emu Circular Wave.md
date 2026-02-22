# Emu Causality Theory  
## Chapter 9 — Circular Wave Representation and Radial Geometry of Causal Expansion

The breadth-first nature of Emu avalanches admits a natural geometric interpretation.

An avalanche may be visualized as a circular causal wave propagating outward in discrete radial layers.

This chapter formalizes that geometric embedding.

![Circular Wave Diagram](docs/images/circular_wave.png)

---

## 1. Generational Circles

Let:

    Gₖ = set of events at generation k

We embed each generation onto a circular orbit of radius:

    rₖ

with:

    rₖ₊₁ > rₖ

Interpretation:

- Radial coordinate → causal depth
- Angular coordinate → ordering within generation
- Orbit circumference → potential capacity of that generation

Thus:

- Generation 0 lies at the center.
- Generation 1 forms the first orbit.
- Generation 2 forms the second orbit.
- And so on.

This embedding reflects strict breadth-first layering.

---

## 2. Orbit as Causal Layer

Because of the Monotone Generation Theorem:

- All events in Gₖ are delivered before any event in Gₖ₊₁.

Thus:

- The processor moves sequentially along orbit Gₖ.
- While moving, it constructs orbit Gₖ₊₁.
- Once Gₖ is exhausted, the wave advances outward.

The frontier corresponds to the boundary between:

- The drained orbit (past),
- The active orbit (present),
- The partially constructed outer orbit (future).

---

## 3. Radial Metrics

### 3.1 Depth as Radius

Causal depth:

    Depth = max { k | Gₖ ≠ ∅ }

corresponds to the outermost radius reached.

Thus:

- Larger radius → deeper causal propagation.

---

### 3.2 Width as Circumference

Generation width:

    Width(k) = |Gₖ|

may be visualized as occupancy along the circumference of orbit rₖ.

Circumference scales as:

    Cₖ ∝ 2π rₖ

Thus the outer orbit has geometrically greater capacity.

This reflects potential multiplicative expansion.

---

### 3.3 Volume as Area

Total avalanche volume:

    Volume = Σₖ |Gₖ|

may be interpreted geometrically as cumulative occupied area across all orbits.

In expanding systems, this resembles disk growth.

---

## 4. Expansion Regimes in Radial Form

Let:

    λₖ = |Gₖ₊₁| / |Gₖ|

Then:

- λₖ > 1 → outer orbit grows
- λₖ = 1 → steady radius
- λₖ < 1 → contraction

Thus:

- Supercritical avalanche → expanding radial wave
- Critical avalanche → constant-width wave
- Subcritical avalanche → collapsing wave

Radial acceleration corresponds to sustained λₖ > 1.

---

## 5. Two-Layer Horizon

From the Two-Generation Frontier Lemma:

At any time, only two consecutive generations coexist in the queue.

In radial geometry:

- The processor moves along orbit rₖ.
- Orbit rₖ₊₁ is partially constructed.
- No deeper orbit exists until rₖ is fully drained.

Thus the frontier is a two-layer circular boundary.

---

## 6. Processor as Rotating Observer

FIFO ordering implies:

- Events within a generation are processed sequentially.
- The processor can be viewed as moving clockwise along the orbit.
- Each processed event becomes part of the inner grey disk (past).

While rotating, it emits new events that populate the outer orbit.

This preserves strict radial ordering.

---

## 7. Resource Interpretation

In radial terms:

- Queue size ≈ arc length of active + next orbit.
- MaxQueueSize ≈ maximum combined circumference of two adjacent orbits.
- Memory pressure corresponds to orbit circumference growth.
- Total work corresponds to total filled area.

If radial growth exceeds available memory envelope,
the engine cannot accommodate the expanding wave.

---

## 8. Divergence as Radial Explosion

In supercritical systems with cycles:

- Radius grows without bound.
- Circumference grows.
- Area grows superlinearly.
- Memory demand diverges.

Termination corresponds to:

    |Gₖ₊₁| = 0

meaning no further outer orbit is constructed.

The wave collapses.

---

## 9. Summary

The circular embedding provides a complete geometric interpretation:

- Radial coordinate → causal depth
- Circumference → generation width
- Disk area → avalanche volume
- Radial growth → expansion factor
- Two-layer boundary → FIFO frontier

Emu avalanches can therefore be understood as:

> Deterministic circular causal waves propagating outward in discrete radial layers.

This geometric representation unifies:

- Breadth-first evaluation
- Generation structure
- Stability regimes
- Resource constraints
- Divergence patterns

It provides an intuitive and mathematically consistent visualization of deterministic causal expansion.