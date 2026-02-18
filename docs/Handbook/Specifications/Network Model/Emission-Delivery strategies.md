# Comparison of Emission–Delivery Strategies

This section compares the two dynamic strategies for
event propagation in a Deterministic Network of Reactive State Machines.

- **Approach 1 — Late Routing (Emission-Based Scheduling)**
- **Approach 2 — Early Routing (Delivery-Based Scheduling)**

---

# 1. Approach 1 — Late Routing Semantics

Pending sequence contains:

    (src, op, v)

Routing is applied at dequeue time.

One emitted value may produce multiple atomic delivery steps.

---

## 1.1 Advantages

### 1. Natural Causality Grouping

All atomic steps originating from a single emitted value
are grouped under one parent event:

    (src, op, v)
        → delivery to dst₁
        → delivery to dst₂
        → ...

This provides:

- Clear fan-out traceability
- Natural reaction blocks
- Strong causal reconstruction

---

### 2. Smaller Pending Queue

Only one object per emission is stored.

Fan-out expansion occurs later,
so memory usage may be smaller.

---

### 3. Strong Structural Integrity

The queue contains only events that:

- originate from valid node output ports
- are guaranteed to be well-formed

There is no possibility of injecting arbitrary
destination-targeted events.

---

### 4. Dynamic Routing Compatibility

If routing changes during execution,
delivery reflects the current routing.

Routing decisions are not frozen at enqueue time.

---

### 5. Halt-Aware Delivery

If a node halts before delivery,
no stale delivered events exist in the queue.

---

## 1.2 Disadvantages

### 1. One Dequeue May Produce Multiple Snapshots

Processing a single emission may require
multiple atomic delivery steps.

This complicates:

- Step accounting
- Some forms of analysis
- Certain debugging views

---

### 2. More Complex Dequeue Phase

Routing expansion must be handled during delivery.

---

# 2. Approach 2 — Early Routing Semantics

Pending sequence contains:

    (dst, ip, v)

Routing is applied immediately at enqueue time.

One dequeue corresponds to exactly one atomic state update.

---

## 2.1 Advantages

### 1. Simpler Atomic Model

One dequeue → one state update → one snapshot.

The operational semantics is structurally simpler.

---

### 2. Direct Injection

External events can be scheduled directly
to specific nodes and ports.

No need for auxiliary source nodes.

---

### 3. Natural Node-Isolated Testing

Ideal for:

- Testing a single complex node
- Small networks
- Unit-level analysis

---

## 2.2 Disadvantages

### 1. Loss of Native Causality Grouping

Fan-out from one emission is flattened
into multiple independent queue entries.

To reconstruct parent–child relationships,
additional metadata is required.

---

### 2. Larger Pending Queue

Each emission expands immediately
into potentially many delivered events.

---

### 3. Frozen Routing Decisions

Routing is resolved at enqueue time.

If routing changes later,
queued delivered events do not reflect the new structure.

---

### 4. Possible Stale Deliveries

If a node halts after routing expansion,
pending delivered events targeting it may remain.

Additional pruning logic may be required.

---

# 3. Equivalence Conditions

The two approaches produce identical global state evolution
under the following conditions:

1. The routing relation R is static during execution.
2. Subscriber ordering is fixed and identical.
3. Node halt behavior is treated consistently.
4. Event processing order is preserved.

Under these conditions:

    Early Routing =
        Eager expansion of Late Routing

Formally:

    Expand(src, op, v) =
        [ (dst₁, ip₁, v), ..., (dst_m, ip_m, v) ]

Approach 2 is equivalent to applying Expand
at enqueue time instead of dequeue time.

The sequence of node state updates remains identical.

---

# 4. Conceptual Positioning

Approach 1 emphasizes:

- Port-level causality
- Reaction grouping
- Structural integrity
- Dynamic topology compatibility

Approach 2 emphasizes:

- Simplicity
- Direct delivery
- Node-centric execution
- Operational minimalism

---

# 5. Recommended Use

Canonical network semantics:
    Approach 1 (Late Routing)

Node-level testing or simplified execution:
    Approach 2 (Early Routing)

Both are valid realizations of the same
Deterministic Network of Reactive State Machines model,
under the stated equivalence conditions.
