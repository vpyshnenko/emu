# STEP 6 — Termination Conditions

This section defines termination and non-termination
for a Deterministic Network of Reactive State Machines
under run-to-completion external injection semantics.

The system state is a Snapshot:

    Snapshot = (σ, E)

where:

- σ : NodeId → State
- E ∈ List(EmittedValue)

Internal transitions:

    (σ, E) → (σ', E')        defined only when E ≠ [].

External injection:

    (σ, []) ↦ (σ, [e])       defined only when E = [].

---

## 1. Quiescence

A Snapshot (σ, E) is **quiescent** iff:

    E = [].

Quiescence means:

- No internal transition is defined.
- The system is stable.
- Further evolution requires external injection.

Quiescence is not termination of the system model.
It is the absence of pending internal activity.

---

## 2. Avalanche Termination

Given a quiescent Snapshot S₀ and an injected emission e:

    S₀ ↦ S₁ →* S₂

The avalanche induced by e **terminates**
iff there exists a finite internal reduction sequence

    S₁ →* S₂

such that S₂ is quiescent.

If no such finite S₂ exists,
the avalanche is **divergent**.

---

## 3. Divergence

An avalanche diverges if there exists an infinite sequence:

    S₁ → S₂ → S₃ → ...

Such divergence corresponds to:

- Infinite emission generation,
- Infinite cyclic causality,
- Non-stabilizing internal activity.

In a divergent avalanche:

- The system never reaches quiescence,
- No further external injection is possible.

---

## 4. Global Termination over an Injection Sequence

Let:

- S₀ be an initial quiescent Snapshot,
- I = [e₁, e₂, …, eₙ] a finite injection sequence.

Execution produces:

    S₀
      ↦ e₁ →* S₁
      ↦ e₂ →* S₂
      ...
      ↦ eₙ →* Sₙ

The execution **terminates successfully**
iff:

- Each avalanche induced by eᵢ terminates, and
- Sₙ is quiescent.

Thus, termination is defined relative to a finite injection sequence.

---

## 5. Infinite Injection Sequences

If the injection sequence is infinite:

    I = [e₁, e₂, e₃, …]

then execution defines an infinite sequence of stabilized Snapshots:

    S₀, S₁, S₂, S₃, …

The system is non-terminating by construction,
but each avalanche may still terminate individually.

---

## 6. Structural Sources of Non-Termination

Non-termination may arise from:

1. Cyclic routing structures.
2. Transition functions that emit unboundedly.
3. Self-sustaining emission cycles.
4. Unbounded state growth leading to perpetual emission.

Termination properties therefore depend on:

- The network topology R,
- The transition functions δₙ,
- The injected emissions.

The model itself does not guarantee termination.

---

## 7. Termination Independence from Observation

Termination is defined solely by the internal transition relation.

Observation does not affect termination.

Termination depends only on:

- The initial Snapshot,
- The injection sequence.

---

## 8. Summary

The model admits three fundamental execution outcomes:

1. **Quiescent stabilization**  
   A finite avalanche reaches E = [].

2. **Divergent avalanche**  
   Internal transitions continue indefinitely.

3. **Infinite external interaction**  
   An infinite injection sequence yields an infinite execution trace.

Termination is therefore:

- Relative to injection,
- Deterministic,
- Fully defined by the transition relation.
