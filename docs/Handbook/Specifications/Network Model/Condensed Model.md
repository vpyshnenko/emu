# Emu — Concise Mathematical Specification

## 1. Identity

Emu is a **deterministic, untimed, run-to-completion network of communicating reactive state machines** with a single global FIFO frontier and late routing semantics.

It defines a deterministic labeled transition system and, at macro level, a deterministic action of event sequences on global state.

---

## 2. Ontology

Primitive domains:

- NodeId
- InPortId
- OutPortId
- Value
- State

Emitted value:

    e = (src : NodeId, op : OutPortId, v : Value)

Global state:

    σ : NodeId → State

Snapshot:

    S = (σ, E)

where:

- E ∈ List(EmittedValue)
- E is FIFO ordered.

---

## 3. Static Structure

For each node n:

    δₙ : State × InPortId × Value
         → State × List(OutPortId × Value)

Routing relation:

    R ⊆ (NodeId × OutPortId)
          ×
         (NodeId × InPortId)

Deterministic subscriber ordering:

    Subs(src, op) = ordered list of (dst, ip)
                    derived from R.

All sets are finite.

---

## 4. Internal Transition (Small-Step)

Defined only when E ≠ [].

If:

    E = (src, op, v) :: E_rest

Let:

    Subs(src, op) = [(dst₁, ip₁), …, (dstₖ, ipₖ)]

Define:

    (σ₀, E₀) = (σ, E_rest)

For i = 1..k:

    (sᵢ', outsᵢ) =
        δ_{dstᵢ}( σᵢ₋₁(dstᵢ), ipᵢ, v )

    σᵢ = σᵢ₋₁[ dstᵢ ↦ sᵢ' ]

    Eᵢ = Eᵢ₋₁ ++
          [(dstᵢ, op', w) for (op', w) in outsᵢ]

Result:

    (σ, (src,op,v)::E_rest)
        →
    (σₖ, Eₖ)

Properties:

- Only one node state is updated per delivery.
- Emissions are appended to the tail.
- Routing expansion is performed at dequeue time (late routing).

---

## 5. External Injection

Defined only when E = [] (quiescence).

For emitted value e:

    (σ, [])
        ↦
    (σ, [e])

Injection is undefined when E ≠ [].

No other external interaction exists.

---

## 6. Avalanche (Run-to-Completion)

An avalanche is the maximal finite sequence:

    S₁ → S₂ → … → Sₙ

starting from a Snapshot with a single injected emission,
ending in a quiescent Snapshot (E = []).

If no such finite Sₙ exists, the avalanche diverges.

---

## 7. Macro-Step Semantics

Define macro operator for emission e:

    Φ_e : Σ → Σ

where:

    Φ_e(σ)
      =
    π_σ( Avalanche( (σ,[]) ↦ (σ,[e]) ) )

For injection sequence:

    [e₁, …, eₙ]

execution is:

    σₙ
      =
    Φ_{eₙ} ∘ … ∘ Φ_{e₁} (σ₀)

Thus Emu defines a deterministic action:

    Φ : Event* → End(Σ)

---

## 8. Determinism

Given:

- Initial Snapshot S₀
- Injection sequence I

the resulting execution trace is unique.

There is no internal nondeterminism.

---

## 9. Causal Closure

Every emitted value produced during execution
is causally derived from:

- An injected emission, or
- An emission present in the initial Snapshot.

There are no spontaneous transitions.

All state updates occur only during delivery of emissions.

---

## 10. Termination and Divergence

An avalanche terminates iff
its induced causal tree is finite.

Sufficient condition for guaranteed termination:

- Routing graph is acyclic, and
- Each δₙ emits a uniformly bounded number of outputs.

Divergence may arise from:

- Productive routing cycles,
- Self-feeding nodes,
- Persistent emission in δ,
- Unbounded state-driven emission.

---

## 11. Failure Conditions

Execution transitions to ⊥ (Failure) if:

- Invalid injection (unknown node or port),
- Invalid routing target,
- Structural inconsistency,
- Step bound or lifetime bound exceeded.

Delivery to halted nodes produces no effect and is not failure.

Failure is terminal.

---

## 12. State Invariants

For every reachable Snapshot:

- All events in E reference existing nodes.
- All op ∈ OutPorts(src).
- Routing targets reference valid nodes and ports.
- FIFO ordering is preserved.
- Only delivered nodes change state.
- Injection occurs only at quiescence.

Invariants are preserved by all valid transitions.

---

## 13. Algebraic Characterization

Emu induces a deterministic monoid action:

    Φ : Event* → End(Σ)

where:

- Event* is the free monoid of injection sequences,
- Σ is the set of global states,
- Composition corresponds to sequential injection.

The system is:

- Deterministic,
- Non-commutative,
- Non-invertible,
- Causally closed,
- Parametric in δ.

---

## 14. Parametric Nature

The engine is parametric in the family {δₙ}.

Correctness requires only:

- δₙ is deterministic,
- δₙ is total (or failure is explicit),
- δₙ respects declared port sets.

The engine does not depend on how δₙ is implemented.

---

## Summary

Emu is a deterministic, untimed, run-to-completion
network of reactive state machines with:

- Late routing,
- Global FIFO frontier,
- Strict reactivity,
- Causal closure,
- Explicit failure semantics,
- Deterministic macro-step algebra.

This specification completely defines the behavior of Emu
independently of any concrete implementation.
