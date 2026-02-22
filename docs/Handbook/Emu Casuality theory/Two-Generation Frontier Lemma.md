# Emu Causality Theory  
## Chapter 7 — The Two-Generation Frontier Lemma

This chapter formalizes a fundamental structural property of first-kind causal processors such as Emu.

Because Emu evaluates avalanches in breadth-first order using a global FIFO frontier, the pending queue has a strict generational structure.

---

## 1. Definitions

Consider a single avalanche initiated by one injection at quiescence.

Let:

    gen(e)

denote the generation index (causal depth) of event e, defined as:

- gen(e₀) = 0 for the injected event
- If event e' is emitted during delivery of e, then:

      gen(e') = gen(e) + 1

Thus every emission increases generation by exactly one.

Let:

    E_t

be the FIFO queue of pending events at runtime step t.

Define:

    g_t = min { gen(e) | e ∈ E_t }

the minimal generation currently present in the queue.

---

## 2. Lemma (Two-Generation Frontier)

For every runtime step t during an avalanche:

> All events in E_t belong to either generation g_t or generation g_t + 1.

Equivalently:

> The pending queue contains at most two consecutive generations of events.

---

## 3. Proof Sketch

We prove by induction over execution steps.

### Base Case

Immediately after injection:

- E contains only the injected event.
- All events belong to generation 0.

The lemma holds.

---

### Inductive Hypothesis

Assume that before a dequeue step, E contains only events of generations:

    g and g + 1

for some g.

---

### Inductive Step

At this step:

1. The head of the queue is dequeued.
2. Because of FIFO ordering, the dequeued event must belong to generation g.
3. During its delivery, zero or more new events are emitted.
4. Each emitted event has generation:

       gen(new) = g + 1

5. These newly emitted events are appended to the tail of the queue.

Thus after the step:

- Remaining generation g events (if any) remain at the front.
- Newly emitted events belong to generation g + 1.
- No event of generation g + 2 can appear, because two emission steps would be required.

Therefore, the queue still contains only generations g and g + 1.

If generation g becomes empty, then:

    g_t increases to g + 1

and the same reasoning continues.

Hence the lemma holds for all t.

---

## 4. Interpretation

The FIFO frontier behaves as a moving two-layer causal boundary.

At any moment:

- One generation is being drained.
- The next generation is being constructed.
- No deeper generation is visible until the current one is fully processed.

Thus the frontier is not an arbitrary collection of future events.

It is a structured, layered horizon.

---

## 5. Structural Consequences

### 5.1 Strict Breadth-First Layering

The lemma formally guarantees:

- Non-decreasing generation order.
- No causal “skipping” of depth levels.
- Uniform expansion of sibling branches.

---

### 5.2 Frontier as Two-Layer Horizon

The queue can be decomposed as:

    E_t = Remaining(G_g) ⧺ Constructed(G_{g+1})

This provides a precise geometric interpretation:

- Front portion → unprocessed current layer
- Tail portion → partially constructed next layer

---

### 5.3 Memory Implication

Since only two generations coexist:

- MaxQueueSize is bounded by:

      |G_g| + |G_{g+1}|

- Peak memory pressure corresponds to overlap of consecutive layers.

---

## 6. Preconditions

The lemma relies on:

1. Single injection per avalanche (injection only at quiescence).
2. Generation increments exactly by one per emission.
3. Global FIFO frontier discipline.
4. No external interleaving of independent avalanches.

If these conditions are violated (e.g., concurrent injections), the property may fail.

---

## 7. Significance

The Two-Generation Frontier Lemma reveals that:

> The Emu frontier is a structured two-layer causal wave, not an arbitrary future buffer.

This property is a direct consequence of FIFO scheduling and late routing semantics.

It provides a formal foundation for:

- Causal wave geometry
- Memory pressure analysis
- Stability classification
- Resource probing metrics

The lemma completes the structural core of Emu’s causal theory.