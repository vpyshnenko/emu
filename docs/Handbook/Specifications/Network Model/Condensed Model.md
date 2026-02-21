Emu Project Context (Condensed Continuation Prompt)

I am developing Emu, a deterministic execution engine for statically wired networks of communicating Reactive State Machines.

# Emu — Concise Mathematical Specification (Revised)

## 1. Identity

Emu is a **deterministic, untimed, run-to-completion network of communicating reactive state machines** with:

- A single global FIFO frontier,
- Late routing semantics,
- Ordered multisubscription topology,
- Static connectivity,
- Deterministic scheduling.

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

where:

- δₙ is deterministic,
- δₙ is defined only for InPorts(n),
- Each emitted (op, v) satisfies op ∈ OutPorts(n),
- The list of emitted values is ordered and semantically significant.

### Ordered Subscription Mapping

Connectivity is defined by:

    Subs : (NodeId × OutPortId)
            → List(NodeId × InPortId)

For each (src, op):

    Subs(src, op) =
      [(dst₁, ip₁), …, (dstₖ, ipₖ)]

Properties:

- The list is finite.
- Order is semantically significant.
- Duplicates are allowed.
- The network is an ordered directed multigraph.

Topology is static at the semantic level.

---

## 4. Internal Transition (Small-Step, Late Routing)

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

    σᵢ =
        σᵢ₋₁[ dstᵢ ↦ sᵢ' ]

    Eᵢ =
        Eᵢ₋₁ ++
        [(dstᵢ, op', w) for (op', w) in outsᵢ]

Result:

    (σ, (src,op,v)::E_rest)
        →
    (σₖ, Eₖ)

Properties:

- Exactly one node state is updated per delivery.
- Emissions are appended to the tail.
- Emission order returned by δ is preserved.
- Routing expansion occurs at dequeue time (late routing).
- Subscriber order determines delivery order.
- Subscriber order determines enqueue order.

---

## 5. Halt Semantics

A node may enter a halted state.

If node dst is halted, delivery:

- Does not execute δ.
- Does not modify state.
- Produces no emissions.
- Is not failure.

Formally:

    (σ, (src,op,v)::E)
        →
    (σ, E)

for halted destination.

Topology (Subs) is not semantically modified by halting.

### Permitted Optimization

Implementations may skip or prune subscriptions targeting halted nodes provided:

- Delivery order for non-halted nodes is preserved.
- Emission trace is unchanged.
- Determinism is preserved.

---

## 6. External Injection

Defined only at quiescence (E = []).

For emitted value e:

    (σ, [])
        ↦
    (σ, [e])

Injection when E ≠ [] is undefined.

No other external interaction exists.

---

## 7. Avalanche (Run-to-Completion)

An avalanche is the maximal sequence:

    S₁ → S₂ → … → Sₙ

starting from a single injected emission and ending in a quiescent snapshot (E = []).

If no finite quiescent snapshot exists, the avalanche diverges.

---

## 8. Macro-Step Semantics

Define:

    Φ_e : Σ → Σ

such that:

    Φ_e(σ)
      =
    π_σ( Avalanche( (σ,[]) ↦ (σ,[e]) ) )

For injection sequence [e₁,…,eₙ]:

    σₙ =
    Φ_{eₙ} ∘ … ∘ Φ_{e₁} (σ₀)

Thus Emu defines deterministic action:

    Φ : Event* → End(Σ)

---

## 9. Determinism

Given:

- Initial snapshot S₀,
- Injection sequence I,

the execution trace is unique.

There is no internal nondeterminism.

Determinism depends on:

- Deterministic δₙ,
- Fixed subscriber ordering,
- FIFO frontier discipline.

---

## 10. Causal Closure

Every emitted value is causally derived from:

- An injected emission, or
- A previously emitted value.

There are no spontaneous transitions.

All state updates occur only during delivery.

---

## 11. Termination and Divergence

An avalanche terminates iff the induced causal expansion is finite.

Sufficient condition for guaranteed termination:

- The directed graph induced by Subs is acyclic, and
- Each δₙ emits a uniformly bounded number of outputs.

Divergence may arise from:

- Productive routing cycles,
- Self-feeding nodes,
- Persistent emission in δ,
- Unbounded state-driven emission.

---

## 12. Failure Conditions

Execution transitions to ⊥ (Failure) if:

- Invalid injection (unknown node or port),
- Invalid routing target,
- Structural inconsistency,
- Explicit δ failure.

Delivery to halted nodes is not failure.

### Resource Bounds

Implementations may impose resource limits (fuel).

Fuel exhaustion is an implementation-defined bounded stop and is not part of the core mathematical semantics.

---

## 13. State Invariants

For every reachable snapshot:

- All events in E reference valid nodes and ports.
- op ∈ OutPorts(src) for all events.
- FIFO ordering preserved.
- Only delivered nodes change state.
- Injection occurs only at quiescence.
- Subscriber ordering preserved.

---

## 14. Algebraic Characterization

Emu induces a deterministic monoid action:

    Φ : Event* → End(Σ)

It is:

- Deterministic,
- Non-commutative,
- Non-invertible,
- Causally closed,
- Parametric in δ.

---

## 15. Parametric Nature

The engine is parametric in {δₙ}.

Correctness requires:

- δₙ deterministic,
- δₙ total (or explicit failure),
- δₙ respects declared ports,
- Emission order returned by δₙ is preserved.

The engine does not depend on how δₙ is implemented.

---

## Summary

Emu is a deterministic, untimed, run-to-completion network of reactive state machines with:

- Late routing,
- Global FIFO frontier,
- Ordered multisubscription topology,
- Static connectivity,
- Strict reactivity,
- Causal closure,
- Explicit failure semantics,
- Deterministic macro-step algebra,
- Parametric local semantics.

This specification completely defines the behavior of Emu independently of any concrete implementation.