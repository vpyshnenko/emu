# Engine Requirements to Eliminate Engine-Induced Divergence

This section states conditions the Engine must satisfy so that any
observed divergence is attributable only to the Network instance
(topology R, local transitions δ, and injection schedule),
not to evaluator artifacts.

The engine must be a sound and complete implementation of the
abstract transition relation. In particular it must preserve:

- FIFO order of the pending frontier,
- Late routing expansion,
- Exactly-once processing of dequeued emissions,
- Run-to-completion avalanche semantics.

---

## 1. Non-Inflation (No Spurious Event Creation)

**Requirement (Exact Enqueue):**  
The engine may enqueue emitted values **only** if they are returned by a node
transition during a valid delivery step, or are provided by external injection
(at quiescence).

Equivalently:

- The engine must not synthesize events.
- The engine must not duplicate emitted events.
- The engine must not re-enqueue an event unless δ explicitly emitted it again.

**Why:** Spurious creation/duplication can turn a terminating avalanche into a divergent one.

---

## 2. Exactly-Once Dequeue Processing

**Requirement (Consume Once):**  
Each pending emission removed from the head of the frontier is processed at most once.

Formally, for the head emission \(e\):

- Dequeue removes \(e\) from \(E\).
- The engine never reintroduces \(e\) into \(E\) unless δ emits an identical value.

**Why:** Reprocessing the same head emission (by bug, rollback, exception retry, etc.)
creates evaluator-induced nontermination.

---

## 3. FIFO Discipline (No Starvation, No Reordering)

**Requirement (FIFO Preservation):**

- The head of \(E\) is always the next emission to be expanded.
- Newly produced emissions are appended to the tail.
- No insertion at head, no priority queueing, no shuffling.

**Why:** Reordering can create apparent “infinite cascades” by starving older events,
even when the abstract model would drain the queue.

---

## 4. Late Routing Expansion (No Early Fan-Out Side Effects)

**Requirement (Late Routing):**  
Subscriber expansion uses the routing relation \(R\) at the moment of dequeue,
and delivery steps correspond to the ordered list \(Subs(src,op)\).

**Why:** Early routing + retries + dynamic checks can cause duplication or loss,
which can change termination behavior.

---

## 5. Deterministic Subscriber Ordering

**Requirement (Stable Subs):**  
For each \((src,op)\), the subscriber list \(Subs(src,op)\) must be deterministic
and stable across the run.

**Why:** If subscriber ordering is nondeterministic, a terminating instance may
appear divergent due to inconsistent interleavings (especially with cycles).

---

## 6. No Mid-Avalanche Injection

**Requirement (Avalanche Isolation):**  
External injection is accepted only when \(E = []\).

**Why:** Mid-avalanche injection can interleave causal chains and produce an
apparent infinite run where each avalanche would terminate in isolation.

---

## 7. Progress / Total Engine Step

**Requirement (Progress When Non-Quiescent):**  
If \(E \neq []\) and no failure is triggered, the engine must perform an internal step.

This implies:

- No deadlocks in evaluator logic.
- No waiting for external input while events remain pending.

**Why:** A buggy engine can “hang” and be mistaken for divergence.

---

## 8. Atomicity of Delivery Steps

**Requirement (Atomic Delivery):**  
A single delivery step (one subscriber delivery) must be executed atomically:

- It updates exactly one destination node state.
- It produces a finite emission list.
- It appends those emissions exactly once.

If a delivery step fails, the engine must transition to ⊥ (Failure),
not partially apply and retry.

**Why:** Partial application + retry loops can create infinite evaluator behavior.

---

## 9. Purity of Observation and Instrumentation

**Requirement (Non-Interference):**  
Tracing, logging, history construction, indexing, and observation must not affect:

- enqueue/dequeue order,
- the number of events enqueued,
- the set of deliveries performed,
- node state updates.

**Why:** Instrumentation bugs can create duplicates, reorder, or accidentally re-run steps.

---

## 10. Failure on Resource Guards (No Silent Truncation)

**Requirement (Guard Transparency):**  
If the engine enforces bounds (step limits, fuel, memory limits), then on violation:

- It must transition to ⊥,
- It must not silently stop early and report quiescence.

**Why:** Silent truncation can hide divergence or create inconsistent termination reports.

---

## 11. Soundness/Completeness Condition (Meta-Requirement)

The engine must satisfy:

- **Soundness:** every concrete step corresponds to a valid abstract step.
- **Completeness:** every abstract step is realizable by the engine.

Consequence:

> If the abstract model terminates for a given (σ₀, schedule),
> then the engine terminates (or fails only by declared guards).
> If the engine diverges without guard failure, the abstract model diverges.

This is the formal “no engine-induced divergence” guarantee.

---

## 12. Practical Checklist (Implementation-Oriented, Semantics-Preserving)

To meet the above requirements, an implementation must ensure:

- Queue is single-writer/controlled (no hidden concurrent enqueues).
- Dequeue is destructive and idempotence-protected.
- Subscriber iteration is stable (avoid map iteration order dependence).
- Emission append preserves order exactly as returned by δ.
- History/tracing is write-only w.r.t. execution state.
- Guard failures are explicit failures, never silent returns.

---

## Summary

Engine-induced divergence is eliminated if the engine:

1. Never creates or duplicates events beyond δ and injection.
2. Processes each dequeued event exactly once.
3. Preserves FIFO and stable subscriber order.
4. Enforces avalanche isolation (no mid-avalanche injection).
5. Ensures progress and atomicity.
6. Makes guards fail explicitly rather than truncating.

Under these conditions, any remaining divergence is intrinsic to the
network instance: topology R, δ behavior, and external injection schedule.
