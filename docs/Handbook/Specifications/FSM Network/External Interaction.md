# STEP 4 — External Injection

This section defines the external injection semantics of a
Deterministic Network of Reactive State Machines under the
canonical Late Routing model.

The system state is a Snapshot:

    Snapshot = (σ, E)

where:

- σ : NodeId → State
- E ∈ List(EmittedValue)

An Emitted Value has the form:

    (src, op, v)

with:

- src ∈ NodeId
- op ∈ OutPortId
- v ∈ Value

Internal evolution is governed by the small-step relation:

    (σ, E) → (σ', E')

defined only when E ≠ [].

This chapter defines how external emissions enter the system
and constrains when injection is permitted.

---

## 1. Pure Reactivity

Emu is strictly reactive.

There are no spontaneous transitions.

Formally:

If

    (σ, E) → (σ', E')

then

    E ≠ [].

Equivalently:

If E = [], no internal transition is defined.

Thus:

- Nodes execute only in response to dequeued emissions.
- All emitted values produced during execution are causally derived
  from previously existing emissions.
- No node can initiate activity independently.

All activity is ultimately rooted in external injection
or emissions present in the initial snapshot.

---

## 2. External Injection Operation

The environment may inject an Emitted Value:

    Inject(src, op, v)

subject to:

- src ∈ NodeId
- op ∈ OutPorts(src)
- v ∈ Value

Injection transforms a Snapshot as follows:

    (σ, [])
        ↦
    (σ, [(src, op, v)])

Injection:

- Appends a single emitted value to an empty frontier.
- Does not modify σ.
- Does not execute any node directly.
- Does not bypass routing.
- Does not alter scheduling.

Injection is undefined when the frontier is non-empty.

---

## 3. Quiescent Snapshots

A Snapshot (σ, E) is **quiescent** iff:

    E = [].

Only quiescent snapshots admit external injection.

Formally:

    Inject(e) is defined on (σ, E)
    iff E = [].

Therefore, injection during internal reduction
is impossible.

---

## 4. Avalanche Semantics

Given a quiescent snapshot:

    S₀ = (σ, [])

and an injected emission e,

define:

1. Injection:

       S₀ ↦ S₁ = (σ, [e])

2. Internal reduction to quiescence:

       S₁ →* S₂

   where S₂ = (σ', [])

The sequence

       S₁ →* S₂

is called the **avalanche induced by e**.

An avalanche is the maximal internal reduction
sequence starting from a single injected emission
and ending at quiescence.

---

## 5. External Execution Over an Injection Sequence

Let:

- S₀ be an initial quiescent snapshot,
- I = [e₁, e₂, …, eₙ] be a finite sequence of injected emissions.

Execution is defined inductively:

    S₀
      ↦ e₁ →* S₁
      ↦ e₂ →* S₂
      ↦ e₃ →* S₃
      ...
      ↦ eₙ →* Sₙ

Each injection is followed by full stabilization
before the next injection is applied.

---

## 6. No Interleaving Property

Let eᵢ and eᵢ₊₁ be consecutive injected emissions.

Then:

- All internal transitions causally derived from eᵢ
  complete before eᵢ₊₁ is injected.
- No emission derived from eᵢ₊₁ can be processed
  before the avalanche of eᵢ reaches quiescence.
- The pending frontier never simultaneously contains
  emissions originating from two distinct external injections.

Thus, execution decomposes into a concatenation
of causally isolated avalanche segments.

---

## 7. Determinism Relative to Injection

Given:

- An initial quiescent snapshot S₀,
- A fixed injection sequence I,

the resulting sequence of stabilized snapshots
S₀, S₁, …, Sₙ

is uniquely determined.

All nondeterminism in the system is confined
to the choice of the external injection sequence.

---

## 8. Summary of Transition Structure

The complete system has exactly two kinds of transitions:

1. Internal step:

       (σ, E) → (σ', E')
       defined only when E ≠ [].

2. External injection:

       (σ, []) ↦ (σ, [e]).

No other transitions exist.

This enforces:

- Strict reactivity,
- Run-to-completion behavior per injection,
- Causal isolation of externally induced activity,
- Deterministic macro-step execution.

---

## 9. Causal Closure

Because nodes cannot initiate activity autonomously:

- Every emitted value has a finite causal ancestry.
- The execution trace forms a directed acyclic causal graph
  rooted in external injections.

This property is fundamental to Emu’s reasoning model.
