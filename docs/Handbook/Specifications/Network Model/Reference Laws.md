# STEP 9 — Reference Laws

This section states the fundamental algebraic laws of the
Deterministic Network of Reactive State Machines.

These laws characterize the model independently of any
implementation and ensure reimplementability.

Let a Snapshot be:

    S = (σ, E)

with:

- σ : NodeId → State
- E ∈ List(EmittedValue)

Internal transition:

    (σ, E) → (σ', E')

External injection:

    (σ, []) ↦ (σ, [e])

All laws below apply to well-formed networks.

---

## 1. Locality Law

**Node transitions are local.**

For any node n, input port ip, and value v:

    δₙ : State × InPortId × Value
         → State × List(OutPortId × Value)

The result of δₙ depends only on:

    (σ(n), ip, v)

It does not depend on:

- The state of any other node m ≠ n,
- The global frontier E,
- The routing relation R,
- The injection schedule.

Formally:

If

    σ₁(n) = σ₂(n)

then

    δₙ(σ₁(n), ip, v) = δₙ(σ₂(n), ip, v).

Thus, node behavior is purely local and deterministic.

---

## 2. State Isolation Law

A delivery to node n modifies only σ(n).

If:

    (σ, E) → (σ', E')

due to delivery to node n,

then:

    σ'(m) = σ(m)   for all m ≠ n.

Thus, internal transitions do not mutate unrelated nodes.

---

## 3. FIFO Preservation Law

The pending frontier E is FIFO ordered.

Let:

    E = e₁ :: e₂ :: ... :: e_k

Then:

- The next internal step always dequeues e₁.
- e₂ cannot be processed before e₁.
- Appended emissions are added to the tail.

Formally:

If

    (σ, e₁ :: E_rest) → (σ', E')

then e₁ is the emission being expanded.

This ensures strict insertion-order processing.

---

## 4. Late Routing Law

Subscriber expansion is determined at dequeue time.

For any emission (src, op, v):

    Subs(src, op)

is evaluated when the emission is dequeued,
not when it is enqueued.

Thus:

- Routing is not pre-expanded.
- Emissions remain atomic until delivery.

---

## 5. Emission Determinism Law

Given:

- Initial Snapshot S₀,
- Injection sequence I,

the resulting execution trace T is unique.

Formally:

If two executions begin from the same S₀
and use identical injection sequences I,

then they produce identical sequences of Snapshots.

Thus:

    Trace(S₀, I) is uniquely determined.

There is no internal nondeterminism.

---

## 6. Avalanche Isolation Law

For injection sequence:

    [e₁, e₂, …, eₙ]

execution decomposes as:

    S₀
      ↦ e₁ →* S₁
      ↦ e₂ →* S₂
      ...
      ↦ eₙ →* Sₙ

No internal step derived from eᵢ₊₁
can occur before stabilization of eᵢ.

Thus, avalanche segments do not interleave.

---

## 7. Causal Closure Law

Every emitted value appearing during execution
is causally derived from:

- An injected emission, or
- An emission already present in the initial Snapshot.

There are no spontaneous emissions.

---

## 8. Structural Preservation Law

If a Snapshot satisfies all State Invariants,
then any Snapshot reachable via:

- Internal transition,
- Valid external injection,

also satisfies all State Invariants.

Safety properties are preserved under execution.

---

## 9. Quiescence Characterization Law

A Snapshot is quiescent iff:

    E = []

At quiescence:

- No internal transition exists.
- State σ is stable.
- Further evolution requires injection.

---

## 10. Deterministic Macro-Step Law

Define macro-step:

    S ↦ₑ S'

meaning:

- Inject e into quiescent S,
- Reduce internally to quiescence.

Then:

    S ↦ₑ S'

is a deterministic function of (S, e).

Thus, the system admits both:

- Micro-step semantics (→),
- Deterministic macro-step semantics (↦ₑ).

---

# Summary

These reference laws guarantee:

- Local computation,
- Isolation of state mutation,
- FIFO processing,
- Deterministic routing expansion,
- Deterministic emission traces,
- Run-to-completion semantics,
- Preservation of safety invariants.

Any conforming implementation must satisfy these laws.
