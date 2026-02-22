# Emu Causality Theory  
## Chapter 3 — Geometry of the Causal Wave

Building on the concepts of:

- Breadth-first causal expansion
- The event horizon (past / present / constructed future)

we now introduce a geometric interpretation of avalanche dynamics.

An avalanche can be viewed as a **discrete causal wave** propagating through the network.

---

## 1. The Causal Wave Model

Each injected event induces a layered expansion:

- Generation 0: injected event
- Generation 1: direct consequences
- Generation 2: consequences of consequences
- …
- Generation D: final layer before termination

We define:

    Gₖ = set of events at causal depth k

Because Emu evaluates breadth-first:

> All events in Gₖ are processed before any event in Gₖ₊₁.

Thus the avalanche unfolds layer by layer.

---

## 2. Depth — Temporal Reach

The **causal depth** of an avalanche is:

    Depth = max { k | Gₖ ≠ ∅ }

Interpretation:

- Longest causal chain from injection.
- Temporal reach of the avalanche.
- Height of the causal expansion tree.

Depth measures how far causality propagates.

---

## 3. Width — Causal Surface Area

For each generation k:

    Width(k) = |Gₖ|

Interpretation:

- Number of parallel events at level k.
- Breadth of causal expansion.
- Surface area of the causal wave at depth k.

The maximum width:

    MaxWidth = maxₖ |Gₖ|

represents peak parallel expansion.

---

## 4. Volume — Total Causal Work

Define:

    Volume = Σₖ |Gₖ|

Interpretation:

- Total number of delivered events.
- Total computational work of the avalanche.

Volume equals the number of delivery steps.

---

## 5. Short-Term Expansion Rate

Define the local expansion factor:

    λₖ = |Gₖ₊₁| / |Gₖ|    (if |Gₖ| > 0)

Interpretation:

- Average branching factor at depth k.
- Measures local amplification or contraction.

If:

- λₖ > 1 → expansion
- λₖ = 1 → steady propagation
- λₖ < 1 → contraction

The peak expansion rate:

    λ_max = maxₖ λₖ

indicates worst-case local amplification.

---

## 6. Queue Size as Instantaneous Surface

At runtime step t:

    QueueSize(t) = |E_t|

The queue represents the currently constructed future.

Queue size approximates:

- The active causal surface.
- The number of inevitable future events.

Important distinction:

- Width(k) measures theoretical generation size.
- QueueSize(t) measures runtime constructed frontier.

They coincide only at exact generation boundaries.

---

## 7. Three Independent Dimensions

Avalanche geometry has three independent dimensions:

1. Depth (temporal reach)
2. Width (parallel surface)
3. Volume (total work)

These dimensions are not reducible to each other.

Examples:

- Deep but narrow avalanche → long chain
- Wide but shallow avalanche → explosive fan-out
- Balanced avalanche → moderate branching

---

## 8. Divergence Patterns

An avalanche may diverge in three ways:

### 8.1 Infinite Depth
Unbounded causal chain.

### 8.2 Infinite Width
Explosive branching in a single generation.

### 8.3 Sustained Expansion
λₖ ≥ 1 persists indefinitely in cyclic topology.

Each corresponds to a different geometric failure mode.

---

## 9. Wave Propagation Interpretation

The avalanche behaves like a discrete wave:

- Depth = propagation distance
- Width = wavefront length
- Volume = total energy expended
- λₖ = local amplification factor

Termination occurs when:

    G_D ≠ ∅ and G_{D+1} = ∅

The wave dissipates.

---

## 10. Memory Implications

Peak memory usage is proportional to:

    MaxQueueSize ≈ MaxWidth

Thus:

- Width governs memory pressure.
- Depth governs execution length.
- Volume governs total work.

This separation allows precise performance analysis.

---

## 11. Summary

An avalanche can be characterized by the tuple:

    (Depth, MaxWidth, Volume, λ_max)

These parameters describe:

- Temporal propagation
- Spatial expansion
- Computational effort
- Growth dynamics

Emu's FIFO discipline ensures that this geometry is observable directly through the frontier.

Thus Emu execution admits a clean geometric interpretation as:

> A deterministic causal wave propagating through a static network.