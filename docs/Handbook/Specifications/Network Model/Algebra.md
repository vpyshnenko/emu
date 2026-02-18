Emu is deterministic event-causal transition algebra

# STEP 10 — Algebraic Structure of Emu

This section presents Emu as an algebraic object.

Beyond being a transition system, Emu induces a deterministic
algebra over global state via externally injected events.

---

## 1. Carrier Set

Let

    Σ = { σ | σ : NodeId → State }

be the set of all possible global states.

A Snapshot is:

    (σ, E)

where E is the FIFO pending frontier.

The algebra will ultimately act on Σ
(via run-to-completion macro-steps).

---

## 2. Primitive Operations (Micro-Level)

Two primitive operations generate execution:

### 2.1 Injection

For each emitted value e:

    Inject_e : Snapshot_quiescent → Snapshot

defined by:

    Inject_e(σ, []) = (σ, [e])

Injection is defined only when the frontier is empty.

---

### 2.2 Dequeue Expansion

    Deq : Snapshot_nonempty → Snapshot

Deq removes the head emission and expands it
via late routing and local transition functions δₙ.

These operations define the small-step semantics.

---

## 3. Avalanche Closure

Define the reflexive–transitive closure of Deq:

    Avalanche : Snapshot → Snapshot

such that:

    Avalanche(S) = S'

where:

    S →* S'  and  S' is quiescent.

Avalanche is a closure operator
that reduces a snapshot to stabilization.

---

## 4. Macro-Step Operator

For each injected emission e,
define the macro-step operator:

    Φ_e : Σ → Σ

as:

    Φ_e(σ) =
        π_σ ( Avalanche( Inject_e(σ, []) ) )

where π_σ extracts the global state from a Snapshot.

Thus, each injection induces
a deterministic transformation of global state.

---

## 5. Injection Sequences

Let:

    I = [e₁, e₂, …, eₙ]

be a finite sequence of injected emissions.

Execution yields:

    σₙ
      =
    Φ_{eₙ} ∘ … ∘ Φ_{e₁} (σ₀)

Thus, execution corresponds to
composition of macro-step operators.

---

## 6. Algebraic Structure

### 6.1 Elements

Global states σ ∈ Σ.

### 6.2 Generators

Emitted values e.

### 6.3 Operations

Macro-step functions Φ_e : Σ → Σ.

### 6.4 Composition

Function composition:

    Φ_{e₂} ∘ Φ_{e₁}

### 6.5 Identity

The empty injection sequence ε acts as identity:

    Id(σ) = σ

---

## 7. Algebraic Laws

### 7.1 Associativity

For any e₁, e₂, e₃:

    Φ_{e₃} ∘ (Φ_{e₂} ∘ Φ_{e₁})
      =
    (Φ_{e₃} ∘ Φ_{e₂}) ∘ Φ_{e₁}

because function composition is associative.

---

### 7.2 Identity Law

The empty injection sequence acts as identity:

    Φ_ε = Id

---

### 7.3 Determinism

For every e and σ:

    Φ_e(σ)

is uniquely defined.

There is no internal nondeterminism.

---

### 7.4 Locality (Lifted)

Each Φ_e is composed of applications of local δₙ functions,
each of which depends only on:

    (σ(n), ip, v)

Thus global transformation is built from local transformations.

---

## 8. Monoid Action

Let:

    Event* = set of all finite emission sequences

with:

- concatenation (·)
- identity element ε

(Event*, ·, ε) forms the free monoid over events.

Emu defines a monoid action:

    Φ : Event* → End(Σ)

such that:

    Φ(e₁ · e₂ · … · eₙ)
      =
    Φ_{eₙ} ∘ … ∘ Φ_{e₁}

Thus, Emu is:

> A deterministic action of the free monoid of injected events
> on the set of global states.

---

## 9. Micro vs Macro Algebra

Two algebraic layers coexist:

### Micro-Level

- Carrier: Snapshots (σ, E)
- Operation: Deq
- Generates causal event trees.

### Macro-Level

- Carrier: Global states Σ
- Operation: Φ_e
- Generates deterministic state transformations.

Macro algebra abstracts away the internal frontier.

---

## 10. Structural Properties

Emu’s algebra is:

- Deterministic
- Non-commutative (order of injections matters)
- Non-invertible (no general inverse Φ_e⁻¹)
- Not commutative
- Not a group
- Not a ring or semiring

It is a deterministic monoid action over state space.

---

## 11. Conceptual Summary

Emu is not merely a transition system.

It induces:

    Φ : Event* → End(Σ)

mapping injection sequences to deterministic
state transformers.

This algebraic structure is:

- Well-defined
- Associative under composition
- Closed under event concatenation
- Deterministic
- Parametric in local transition family δ

This provides a clean algebraic characterization
of Emu’s execution semantics.
