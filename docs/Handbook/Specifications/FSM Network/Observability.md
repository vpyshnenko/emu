# STEP 5 — Observability

This section defines the observable structure of a
Deterministic Network of Reactive State Machines.

Observability in Emu is structural and post-factum.
Execution produces a deterministic trace of Snapshots.
All observable information is derivable from that trace.

Observation does not participate in execution
and does not affect determinism.

---

## 1. Execution Trace

Let

    S₀

be an initial quiescent Snapshot.

Given an injection sequence

    I = [e₁, e₂, …, eₙ]

execution produces a deterministic sequence of Snapshots:

    S₀ → S₁ → S₂ → ... → S_k

This sequence is uniquely determined by:

- The initial Snapshot,
- The injection sequence.

The complete execution trace is the ordered list of
all Snapshots produced during evaluation.

---

## 2. Observability as Projection

An observation is a function over the execution trace:

    Obs : Trace → O

for some observation domain O.

Observation is defined over the completed trace.
It introduces no transitions and no side effects.

Thus, observation does not influence:

- State evolution,
- Routing,
- Scheduling,
- Emission ordering.

---

## 3. Semantic Completeness of Snapshots

Each Snapshot contains:

- The full Global State σ,
- The complete pending frontier E.

Therefore, the trace of Snapshots is semantically complete.

From the trace alone one can reconstruct:

- The state of any node at any step,
- The frontier contents at any step,
- The sequence of dequeued emissions,
- The causal structure within each avalanche.

No semantic information exists outside this trace.

---

## 4. Practical Extractability

Although the trace of Snapshots is complete,
deriving certain observational views directly from it
may be non-trivial.

For example, extracting:

- The stream of values emitted by a specific node,
- The stream of values emitted on a specific output port,
- The values delivered along a particular edge,

requires systematic traversal of the sequence of Snapshots,
inspection of frontier changes,
and reconstruction of emission origins.

This is always possible,
but may be computationally inconvenient.

---

## 5. Derived Execution History

For practical analysis,
one may define a **derived history structure**
computed during evaluation.

A history structure records, for each atomic delivery step:

- The source node and output port,
- The destination node and input port,
- The payload,
- The Snapshot resulting from the step.

Formally, let

    Trace = [S₀, S₁, …, S_k]

A corresponding history sequence may be defined as:

    H = [h₁, h₂, …, h_m]

where each hᵢ encodes the semantic transition
between Sᵢ₋₁ and Sᵢ.

The history is a derived structure:

    H = History(Trace)

It contains no additional semantic information;
it reorganizes information already present in the trace
into an indexed form.

---

## 6. Observational Equivalence

The execution trace and the derived history
are observationally equivalent:

- All queries answerable from H
  are derivable from the trace.
- H introduces no new behavior.
- H does not affect determinism.

Thus, history is a convenience layer,
not a semantic extension.

---

## 7. Determinism of Observation

Because the execution trace is uniquely determined
by the injection sequence,

all derived observational structures
are likewise uniquely determined.

Observation is purely reflective.

It cannot interfere with execution.
