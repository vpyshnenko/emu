# STEP 3 — Dynamics (Approach 2: Early Routing Semantics)

This section defines the dynamic semantics of a
Deterministic Network of Reactive State Machines
under Approach 2 (Delivered Events as pending objects).

In this approach:

- The pending sequence contains **Delivered Events**.
- Routing expansion occurs at enqueue time.
- One dequeue operation corresponds to exactly one atomic state update.

---

## 1. Snapshot

A Snapshot is:

    Snapshot = (σ, D)

where:

- σ : NodeId → State   (Global State)
- D = [ d₁, d₂, ..., d_k ]   (ordered list of Delivered Events)

Each delivered event has the form:

    d = (dst, ip, v)

---

## 2. Event Injection

External interaction introduces delivered events directly:

    (dst, ip, v)

These are appended to the end of D.

---

## 3. Atomic Delivery Step

Let the current Snapshot be:

    (σ, (dst, ip, v) :: D_rest)

Let:

    σ(dst) = s

Compute the local transition:

    (s', outs) = δ_dst(s, ip, v)

where:

    outs = [ (op₁, v₁), ..., (op_k, v_k) ]

Define updated Global State:

    σ' = σ[ dst ↦ s' ]

---

## 4. Routing Expansion (Eager)

Each emitted value (opᵢ, vᵢ) is immediately expanded
according to the subscriber list:

    Subs(dst, opᵢ) =
        [ (n₁, ip₁), ..., (n_m, ip_m) ]

For each subscriber (n_j, ip_j),
generate a Delivered Event:

    (n_j, ip_j, vᵢ)

Collect all such generated delivered events
in subscriber order and emission order.

Denote the resulting list:

    D_emit

Append to the pending sequence:

    D' = D_rest ++ D_emit

---

## 5. Transition Rule

The atomic transition relation is:

    (σ, (dst, ip, v) :: D_rest)
        ⇒
    (σ', D')

where:

- σ' is the updated Global State
- D' is obtained by removing the head delivered event
  and appending all eagerly expanded delivered events

Each atomic transition:

- consumes exactly one delivered event
- updates exactly one node-local state
- appends zero or more delivered events
- produces exactly one new Snapshot

---

## 6. Determinism

If:

- All local transition functions δₙ are deterministic
- Subscriber ordering is fixed
- The pending sequence is processed in order

then the global transition relation is deterministic.
