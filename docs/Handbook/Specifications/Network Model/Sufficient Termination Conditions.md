# STEP 13 — Sufficient Conditions for Guaranteed Termination

This section states sufficient (not necessary) conditions under which
every avalanche induced by a single injected emission terminates.

Termination here means: starting from a quiescent Snapshot and injecting
one emission, the resulting internal reduction reaches a quiescent Snapshot
in finitely many internal steps.

Because Emu is deterministic and run-to-completion, it is sufficient to show
that the number of causally generated emissions is finite.

---

## 1. Preliminaries

Let the network be defined by:

- Nodes ⊆ NodeId (finite)
- Routing relation  
  R ⊆ (NodeId × OutPortId) × (NodeId × InPortId)

- Local transitions  
  δₙ : State × InPortId × Value → State × List(OutPortId × Value)

Let an avalanche start from:

    (σ, [e₀])

and proceed by repeated internal steps until (if possible) E = [].

---

## 2. Acyclic Routing Condition

Define a directed graph on nodes:

- There is an edge n → m if there exist ports op, ip such that:

      ((n, op), (m, ip)) ∈ R

Assume the induced node graph is **acyclic** (a DAG).

Equivalently: there is no sequence of nodes

    n₁ → n₂ → ... → nₖ → n₁.

This rules out topological feedback loops.

---

## 3. Bounded Emission Condition

Assume there exists a finite constant B ≥ 0 such that:

For every node n, every state s, every input port ip, and every value v:

    let (s', outs) = δₙ(s, ip, v) in
    |outs| ≤ B.

This is a uniform bound on the number of outputs a node can produce
per delivered event.

---

## 4. Well-Formedness Assumptions

Assume:

- The routing relation is finite.
- Subscriber lists are finite.
- No failure is triggered (valid ports, etc.).
- δₙ is total and deterministic.

These ensure each internal step is well-defined.

---

## 5. Termination Theorem (Sufficient Condition)

**Theorem.**
If:

1. The routing graph is acyclic, and
2. There exists a uniform emission bound B,

then every avalanche induced by a single injected emission terminates.

---

## 6. Proof Sketch (by Ranking / Topological Height)

Because the routing graph is acyclic, there exists a topological ranking:

    rank : NodeId → ℕ

such that if n → m then:

    rank(n) < rank(m).

Consider any emitted value (src, op, v). When it is expanded,
it produces deliveries only to nodes with strictly higher rank.

Each delivery may emit at most B new emissions, whose sources have
the destination node as src, hence strictly higher rank than the parent emission’s src.

Therefore, along any causal chain, ranks strictly increase.
Since ranks are bounded above by the finite height H of the DAG,
no causal chain can exceed length H.

Moreover, each node delivery emits at most B events, so the branching
factor of the causal tree is bounded.

A finite-height, finitely-branching causal tree is finite.
Hence, only finitely many emissions are generated, so the FIFO frontier
is eventually drained, and quiescence is reached.

---

## 7. Quantitative Bound (Optional)

Let:

- H = maximum rank in the DAG (height)
- D = maximum number of subscribers of any (src, op)

Each processed emission expands into at most D deliveries.
Each delivery produces at most B new emissions.

Thus, a rough upper bound on the number of emissions in the avalanche is:

    1 + (D·B) + (D·B)^2 + ... + (D·B)^H

which is finite for finite H.

This is an over-approximation but suffices to show termination.

---

## 8. Remarks

- Acyclic routing is sufficient but not necessary.
  Cyclic networks may still terminate if δ eventually stops emitting.

- Uniform bounded emission is also sufficient but not necessary.
  Unbounded emission may still terminate if only finitely many outputs
  occur for the specific run.

- The above theorem proves termination by guaranteeing that the causal
  structure is a finite tree.

---

## 9. Practical Sufficient Condition (Common Pattern)

A commonly useful sufficient condition is:

- Routing graph is acyclic, and
- Each δₙ emits at most B outputs per input, and
- The set of nodes is finite.

Under these conditions, every injected event produces a finite avalanche.

---

## 10. Summary

Guaranteed termination of every avalanche holds if:

- No feedback cycles exist in routing (DAG topology), and
- Node transitions have a uniform finite emission bound.

This ensures the causal tree induced by an injection is finite,
so the pending frontier is drained in finitely many steps.
