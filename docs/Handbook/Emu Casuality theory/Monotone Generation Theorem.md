# Emu Causality Theory  
## Chapter 8 — The Monotone Generation Theorem

The Two-Generation Frontier Lemma established that the FIFO frontier
contains at most two consecutive generations.

We now formalize a stronger ordering property:

> Events are delivered in non-decreasing generation order.

This property captures the precise sense in which Emu evaluates
avalanches breadth-first.

---

## 1. Definitions

Let:

    gen(e)

be the generation index (causal depth) of event e.

Let:

    d_t

be the event delivered at runtime step t
(i.e., the event dequeued at step t).

---

## 2. Theorem (Monotone Generation)

For all steps t:

    gen(d_{t+1}) ≥ gen(d_t)

That is:

> The sequence of delivered events has non-decreasing generation indices.

Equivalently:

> No event of a deeper generation can be delivered
> before all events of the previous generation are exhausted.

---

## 3. Proof Sketch

We use the Two-Generation Frontier Lemma.

At any time t:

- The queue contains only events of generations:

      g_t and g_t + 1

where:

      g_t = min { gen(e) | e ∈ E_t }

Because the queue is FIFO:

- The head of the queue must belong to generation g_t.

Thus:

    gen(d_t) = g_t

If after this dequeue:

- Other generation g_t events remain,
  then g_{t+1} = g_t.

- If generation g_t becomes empty,
  then g_{t+1} = g_t + 1.

Therefore:

    gen(d_{t+1}) ≥ gen(d_t)

and generation never decreases.

---

## 4. Consequence: Layer Integrity

The theorem implies:

> All events of generation k are delivered
> before any event of generation k+1 is delivered.

Thus generation layers are processed contiguously.

There cannot exist:

- An event of generation k+1 delivered
- Followed later by an event of generation k

Nor can deeper-generation events appear
“in the middle” of a previous generation group.

FIFO discipline preserves strict layer integrity.

---

## 5. Queue Structure Invariant

At any time t:

    E_t = G_g^rem ⧺ G_{g+1}^partial

where:

- G_g^rem is the remaining portion of generation g
- G_{g+1}^partial is the partially constructed next generation

Thus the queue always has the structure:

    [ current generation remainder | next generation ]

No interleaving of deeper layers is possible.

---

## 6. Significance

The Monotone Generation Theorem formalizes that:

- Emu evaluates causal trees in strict breadth-first order.
- Causal depth increases monotonically.
- The frontier advances in discrete layers.

This is not merely an implementation detail.

It is a semantic invariant induced by:

- Global FIFO frontier
- Late routing
- Emission-at-delivery discipline

---

## 7. Structural Interpretation

Emu execution can be viewed as:

- Draining one causal layer
- While constructing the next
- Then advancing the causal boundary by one depth unit

Thus time in Emu corresponds to
monotone progression of causal depth.

The frontier behaves as a two-layer moving wavefront.

---

## 8. Corollary

If an avalanche terminates at generation D, then:

- All events of generation 0 are delivered,
- Then all events of generation 1,
- …
- Finally all events of generation D.

No generation is partially processed after a deeper one begins.

This completes the formal proof that Emu is a strict
breadth-first causal processor.