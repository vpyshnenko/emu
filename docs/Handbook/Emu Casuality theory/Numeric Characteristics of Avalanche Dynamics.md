# 16. Numeric Characteristics of Avalanche Dynamics

This chapter introduces quantitative measures describing the geometry of causal expansion during an avalanche.

An avalanche is the maximal run-to-completion sequence induced by a single injected emission.

We model the avalanche as a layered causal expansion.

---

## 16.1 Generational Structure

Let the injected event be generation 0.

Define generation sets inductively:

- **G₀** = { injected event }
- For k ≥ 0:

  Gₖ₊₁ = set of all emissions produced by deliveries of events in Gₖ

Each event belongs to exactly one generation determined by its minimal causal distance from injection.

Because Emu uses a global FIFO frontier, events are delivered in non-decreasing generation order.

---

## 16.2 Causal Depth

Let an avalanche terminate after n generations.

Define:

CausalDepth = max { k | Gₖ ≠ ∅ }

Interpretation:

- The longest causal chain from injection.
- Equivalent to the height of the causal tree.
- Measures temporal reach of the avalanche.

---

## 16.3 Frontier Width

At any moment during execution, the FIFO queue contains a mix of:

- Remaining events of current generation Gₖ
- Possibly some already-enqueued events of Gₖ₊₁

Define the generation frontier width at generation k:

Width(k) = |Gₖ|

Interpretation:

- Number of causally parallel events at level k.
- Breadth of the avalanche at that layer.

Peak frontier width:

MaxWidth = maxₖ |Gₖ|

This measures maximum parallel causal surface.

---

## 16.4 Active Frontier Size

At runtime step t, define:

QueueSize(t) = |Eₜ|

where Eₜ is the FIFO queue content.

QueueSize(t) reflects:

- The number of already-determined but not-yet-delivered events.
- The instantaneous causal surface area.

Note:

QueueSize(t) is not necessarily equal to |Gₖ| for a single k, because during transitions between generations the queue may contain a mix of Gₖ and Gₖ₊₁.

---

## 16.5 Short-Term Causal Expansion Rate

Define the per-generation expansion factor:

λₖ = |Gₖ₊₁| / |Gₖ|    if |Gₖ| > 0

Interpretation:

- Average branching factor at generation k.
- Measures local growth or contraction.

Define peak expansion rate:

λ_max = maxₖ λₖ

Interpretation:

- Worst-case local amplification factor.

---

## 16.6 Average Branching Factor

Define:

AvgBranching =
( Σₖ |Gₖ₊₁| ) / ( Σₖ |Gₖ| )

This approximates:

- Average number of emitted events per delivered event.

Equivalent to:

TotalEmitted / TotalDelivered

This reflects global amplification of the avalanche.

---

## 16.7 Avalanche Volume

Define:

Volume = Σₖ |Gₖ|

Interpretation:

- Total number of events processed during avalanche.
- Total causal work performed.

This equals the number of delivery steps.

---

## 16.8 Causal Geometry Summary

Each avalanche can be characterized by the tuple:

( Volume, CausalDepth, MaxWidth, λ_max )

These values describe the geometric profile of the avalanche:

- Depth → temporal reach
- Width → parallel causal surface
- Expansion rate → growth dynamics
- Volume → total computational effort

---

## 16.9 Termination and Divergence Conditions

An avalanche terminates iff:

- Volume is finite,
- CausalDepth is finite,
- All generations Gₖ are finite,
- Eventually |Gₖ| = 0.

Divergence may occur if:

- Depth grows without bound (infinite causal chain), or
- Width grows without bound (explosive branching), or
- Expansion factor λₖ ≥ 1 persists indefinitely in a cyclic topology.

---

## 16.10 Interpretation in Emu

Because Emu evaluates in breadth-first order:

- Generations are processed layer by layer.
- Queue acts as the moving causal surface.
- Expansion rate governs memory growth.
- Depth governs temporal propagation.

Thus Emu avalanches exhibit measurable geometric dynamics analogous to wave propagation in discrete causal media.

---

## Optional Additional Metrics

If desired, further measures may include:

### Surface-to-Volume Ratio

SurfaceRatio = |G_D| / Volume

Indicates whether avalanche terminates gradually or abruptly.

### Width Variance

Measures irregularity of branching across generations.

### Entropy of Branching

If multiple ports contribute differently to expansion, one may measure distribution entropy of emitted ports per generation.

---