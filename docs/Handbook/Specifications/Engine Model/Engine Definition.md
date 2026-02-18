# Engine Definition — Parametric Queue Evaluator

The Emu engine is defined independently of any particular
implementation of local transition functions.

It is a deterministic evaluator over a network of nodes,
a routing relation, and a FIFO event frontier.

---

## 1. Static Components

Given:

- A finite set of nodes  
  Nodes ⊆ NodeId

- A routing relation  
  R ⊆ (NodeId × OutPortId) × (NodeId × InPortId)

- A deterministic subscriber ordering function derived from R:

      Subs(src, op) = [(dst₁, ip₁), …, (dstₖ, ipₖ)]

- A family of deterministic local transition functions:

      δₙ : State × InPortId × Value
           → State × List(OutPortId × Value)

Each δₙ is assumed deterministic and well-defined.

---

## 2. Dynamic State (Snapshot)

A Snapshot is:

      S = (σ, E)

where:

- σ : NodeId → State
- E ∈ List(EmittedValue)

An EmittedValue has the form:

      (src, op, v)

The list E is FIFO ordered.

---

## 3. Internal Dequeue Step (Late Routing)

The internal step relation is defined only when E ≠ [].

If:

      E = (src, op, v) :: E_rest

then subscriber expansion occurs at dequeue time.

Let:

      Subs(src, op) = [(dst₁, ip₁), …, (dstₖ, ipₖ)]

Define a sequence of intermediate Snapshots:

      (σ₀, E₀) = (σ, E_rest)

For each i = 1 … k:

1. Compute local transition:

      (sᵢ', outsᵢ) =
          δ_{dstᵢ}( σᵢ₋₁(dstᵢ), ipᵢ, v )

2. Update only the destination node:

      σᵢ = σᵢ₋₁[ dstᵢ ↦ sᵢ' ]

3. Append emitted values to the tail of the frontier:

      Eᵢ = Eᵢ₋₁ ++ EmitList(dstᵢ, outsᵢ)

where:

      EmitList(dst, [(op₁,w₁), …, (opₘ,wₘ)])
        =
      [(dst,op₁,w₁), …, (dst,opₘ,wₘ)]

The result of processing the dequeued emission is:

      DeqStep(σ, (src,op,v)::E_rest)
        =
      (σₖ, Eₖ)

This defines one internal transition of the engine.

---

## 4. External Injection

External injection is defined only on quiescent Snapshots.

A Snapshot (σ, E) is quiescent iff:

      E = []

Injection of emission e transforms:

      (σ, [])
          ↦
      (σ, [e])

Injection is undefined when E ≠ [].

---

## 5. Avalanche (Run-to-Completion)

An avalanche is the maximal iteration of DeqStep
starting from a Snapshot with a single injected emission.

Given:

      S₀ = (σ, [])

and injected emission e:

1. Inject:

      S₁ = (σ, [e])

2. Apply DeqStep repeatedly:

      S₁ → S₂ → … → Sₙ

until Sₙ is quiescent (E = []).

Define:

      Avalanche(S₁) = Sₙ

---

## 6. Macro-Step Semantics

Define the macro-step induced by injection e as:

      Macro(σ, e)
          =
      Avalanche( (σ, []) ↦ (σ, [e]) )

Given an injection sequence:

      [e₁, e₂, …, eₙ]

execution proceeds inductively:

      S₀ = (σ₀, [])

      S₁ = Macro(σ₀, e₁)
      S₂ = Macro(σ₁, e₂)
      …
      Sₙ = Macro(σₙ₋₁, eₙ)

Each macro-step is deterministic.

---

## 7. Parametric Nature of the Engine

The engine depends on δ only through the following contract:

- Locality: δₙ depends only on (σ(n), ip, v).
- Determinism: δₙ is deterministic.
- Port validity: emissions reference valid OutPorts(n).

The engine does not inspect how δₙ is implemented.

It is therefore parametric in the family {δₙ}.

---

## 8. Complete Characterization

The entire engine behavior is defined by:

- The Inject relation,
- The DeqStep relation,
- Iteration of DeqStep until quiescence.

No additional operational rules exist.

This specification completely characterizes
the behavior of the Emu engine
independently of any concrete implementation.
