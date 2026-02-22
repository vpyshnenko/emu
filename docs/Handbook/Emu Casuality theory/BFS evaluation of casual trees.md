# Emu Causality Theory  
## Chapter 1 — Breadth-First Evaluation of Causal Trees

One of the most illuminating structural properties of Emu is:

> Emu evaluates causal trees in breadth-first order.

This is not a metaphor. It is a precise consequence of the FIFO frontier discipline.

Let us examine this carefully.

---

## 1. Every Avalanche Induces a Causal Tree

Consider a single injected event e₀.

During an avalanche:

- e₀ is delivered.
- Its delivery may emit new events.
- Those events may emit further events.
- And so on.

If we draw only causal relations (“this event caused that event”), we obtain a tree (or a DAG if multiple parents exist).

Example:

    e₀
     ├─ e₁
     │   ├─ e₃
     │   └─ e₄
     └─ e₂
         └─ e₅

Each edge means:

    “This event was emitted because of that event.”

This structure is purely causal and exists independently of scheduling.

We call it the causal expansion tree of the avalanche.

---

## 2. Two Classical Evaluation Strategies

There are two fundamental ways to traverse such a tree.

### 2.1 Depth-First Evaluation (DFS)

In depth-first evaluation, a newly produced event is processed immediately.

Execution order example:

    e₀
      → e₁
         → e₃
         → e₄
      → e₂
         → e₅

Characteristics:

- Stack discipline
- LIFO scheduling
- Recursive descent
- One branch expanded deeply before siblings

Recursive state machines and typical function call stacks behave this way.

---

### 2.2 Breadth-First Evaluation (BFS)

In breadth-first evaluation:

> All events at depth d are processed before any event at depth d+1.

Execution order example:

    e₀
    e₁, e₂
    e₃, e₄, e₅

Characteristics:

- Queue discipline
- FIFO scheduling
- Layer-by-layer expansion
- Uniform exploration of siblings

This is exactly how Emu operates.

---

## 3. Why Emu Is Breadth-First

Emu enforces:

- Emissions are appended to the tail of a global FIFO queue.
- Delivery always removes from the head.

Consider the sequence:

1. Inject e₀  
2. Dequeue e₀  
3. Append e₁, e₂  
4. Dequeue e₁  
5. Append e₃, e₄  
6. Dequeue e₂  
7. Append e₅  

Observe:

- e₂ is processed before e₃ and e₄.
- All depth-1 events are processed before depth-2 events.

This is the defining property of BFS traversal.

---

## 4. The Frontier as the Current BFS Layer

In classical BFS terminology:

- The frontier is the set of nodes discovered but not yet processed.
- In Emu, the FIFO queue is exactly that.

At any moment:

- All events before the frontier have been delivered.
- All events beyond it have not yet been generated.
- The frontier is the current causal boundary.

Thus the frontier corresponds to the current BFS layer.

---

## 5. Structural Implications

### 5.1 Deterministic Layering

Events are processed in non-decreasing causal depth.

Depth never decreases.

### 5.2 No Deep Causal Dive

Emu never fully expands one branch while ignoring siblings.

All branches advance together layer by layer.

### 5.3 Fairness Between Branches

Sibling causal branches are treated uniformly.

No branch monopolizes evaluation depth.

---

## 6. Contrast With Recursive Systems

Recursive state machines:

- Use a call stack
- Expand deeply before returning
- Implement depth-first evaluation

Emu instead implements:

    “All immediate consequences before any secondary consequences.”

This yields a fundamentally different computational geometry.

---

## 7. Important Nuance

Emu is not strictly perfect BFS in the pure graph-theoretic sense because:

- Subscriber ordering influences intra-layer ordering.
- Multiple deliveries to the same node may reorder emissions.
- Routing topology may merge branches.

However:

> With respect to causal distance from injection, Emu enforces breadth-first layering.

---

## 8. Why This Is a Semantic Property

Breadth-first behavior is not accidental.

It is forced by three core design decisions:

- Global FIFO frontier
- Late routing semantics
- Append-at-tail emission discipline

Changing any of these could alter traversal geometry.

Thus BFS layering is part of Emu’s semantic identity.

---

## 9. Why This Matters

Breadth-first causal expansion gives Emu:

- Predictable causal layering
- Controlled divergence behavior
- Uniform branch expansion
- Clear separation of width vs depth
- Measurable avalanche geometry

These properties directly influence:

- Termination analysis
- Memory growth
- Divergence patterns
- Quantitative avalanche dynamics

---

## 10. Final Statement

Emu evaluates avalanches by:

> Exploring the causal expansion tree level by level (breadth-first), using a FIFO frontier.

At any time, the frontier is exactly the current boundary of pending causal consequences.

---

## Next Directions

Further analysis may explore:

- What changes if FIFO is replaced by LIFO?
- Would determinism survive?
- Would termination properties change?
- How traversal geometry affects divergence growth?

These comparisons reveal the deep structural role of scheduling discipline in Emu.