# STEP 12 — Divergence Analysis

This section analyzes the causes of divergence in Emu.

Divergence means that an avalanche does not terminate.
Formally, starting from a Snapshot:

    S₁ = (σ, [e])

there exists an infinite sequence:

    S₁ → S₂ → S₃ → …

and no quiescent Snapshot is reached.

Divergence is not a failure of the abstract model;
it is non-termination of the transition relation.
However, its structural causes must be understood.

---

## 1. Proliferation of Events (Queue Growth Imbalance)

Let:

- r_d = average dequeue rate (always 1 per internal step)
- r_e = average number of emissions appended per delivery

If, over time:

    r_e > r_d

then the frontier grows unboundedly.

More precisely:

If there exists a reachable configuration in which
each processed emission generates at least one new emission
in the long run, then the queue cannot be drained.

This leads to:

- Unbounded growth of E,
- Infinite internal reduction,
- Divergence.

This phenomenon is structural proliferation.

---

## 2. Topological Loops (Routing Cycles)

If the routing relation R contains a cycle:

    n₁ → n₂ → … → nₖ → n₁

then emissions may circulate indefinitely.

A routing cycle alone does not guarantee divergence.
It causes divergence only if:

- The composed transition along the cycle
  regenerates emissions perpetually.

Formally, consider the composed transformer:

    T_cycle = Φ_{e_k} ∘ … ∘ Φ_{e_1}

If T_cycle reintroduces at least one emission into the cycle,
divergence may occur.

Thus, divergence requires:

- A cycle in topology,
- A productive transition composition along the cycle.

---

## 3. Self-Feeding Nodes (Local Recursion)

A node n may emit to its own input via routing:

    (n, op) → (n, ip)

If δₙ(s, ip, v) always emits an event
that is routed back to n,
then a single emission may cause infinite self-triggering.

This is a local recursion loop.

Such divergence does not require multi-node cycles;
it can occur within a single node.

---

## 4. δ-Induced Emission Loops

A node transition may emit multiple events
per input.

If the emission pattern of δₙ satisfies:

    |outs| ≥ 1
    and at least one emitted event feeds
    into a path that eventually re-triggers n,

then the handler induces an emission loop.

This can occur even if routing graph is acyclic,
provided emissions return through alternative paths.

---

## 5. Combinatorial Explosion

Even without direct cycles,
divergence can arise from exponential proliferation.

Example structure:

- Node A emits to B and C.
- B and C both emit back to A.
- Each path multiplies event count.

Even if the graph is finite,
branching factors greater than one can cause:

    |Eₖ| → ∞

before any quiescent state is reached.

This is causal branching divergence.

---

## 6. State-Driven Non-Stabilization

Divergence may depend on state evolution.

If δ modifies state in a way that continually
enables further emissions (e.g., counters that never saturate),
then stabilization may be impossible.

This includes:

- Monotonic counters without bounds,
- Accumulators that always trigger threshold emission,
- State oscillation without fixed point.

Thus, divergence can arise from
non-converging state dynamics.

---

## 7. Infinite Initial Frontier

If the initial Snapshot contains
an infinite pending frontier E,
divergence is immediate.

The model assumes E is finite at all times.
Infinite E violates state invariants.

---

## 8. Divergence Classification

Divergence causes can be categorized as:

### Structural
- Cycles in routing graph.
- Self-routing edges.

### Behavioral
- δ emitting persistently.
- Emission multiplicity > 1.

### Dynamical
- State transitions that prevent convergence.
- Oscillatory or monotonic unbounded state growth.

### Quantitative
- Average emission rate ≥ 1 over cycles.

---

## 9. Necessary Condition for Avalanche Termination

For an avalanche to terminate:

There must exist a bound B such that
the total number of emissions causally derived
from a single injected emission is finite.

Equivalently:

The causal tree rooted at the injection
must be finite.

If the causal tree is infinite,
divergence occurs.

---

## 10. Divergence vs Failure

Divergence is not failure in the abstract model.

It is infinite reduction.

An implementation may convert divergence into failure
via step bounds or lifetime limits,
but this is an execution guard, not semantic divergence.

---

## 11. Conceptual Summary

Divergence in Emu arises when:

- The emission graph contains productive cycles, or
- The local transition functions sustain emission indefinitely.

Divergence is fundamentally a property of:

- The routing topology R,
- The family of δₙ,
- The injected emission.

Termination therefore depends on
both structure and local transition behavior.

Understanding divergence requires analyzing:

- Cycles in routing,
- Emission multiplicity,
- State convergence properties,
- Growth rates of the frontier.
