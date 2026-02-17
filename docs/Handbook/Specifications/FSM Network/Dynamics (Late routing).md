# STEP 3 — Dynamics (Approach 1: Late Routing Semantics)

This section defines the dynamic semantics of a
Deterministic Network of Reactive State Machines
under Approach 1 (Emitted Values as pending objects).

In this approach:

- The pending sequence contains **Emitted Values**.
- Routing expansion occurs at dequeue time.
- One atomic step updates exactly one node state.

---

## 1. Snapshot

A Snapshot is:

    Snapshot = (σ, E)

where:

- σ : NodeId → State   (Global State)
- E = [ e₁, e₂, ..., e_k ]   (ordered list of Emitted Values)

Each emitted value has the form:

    e = (src, op, v)

---

## 2. Subscriber Function

For each output endpoint (src, op),
define the ordered subscriber list:

    Subs(src, op) =
        [ (dst₁, ip₁), (dst₂, ip₂), ..., (dst_m, ip_m) ]

such that:

    ((src, op), (dstᵢ, ipᵢ)) ∈ R

The order of Subs(src, op) is part of the static structure.

---

## 3. Atomic Delivery Step

Let the current Snapshot be:

    (σ, (src, op, v) :: E_rest)

Let:

    Subs(src, op) =
        [ (dst₁, ip₁), ..., (dst_m, ip_m) ]

The reaction to this head emission consists of a sequence
of atomic delivery steps, one per subscriber,
processed in the order of Subs(src, op).

---

### Atomic Step (for subscriber i)

Assume the next subscriber to process is:

    (dst, ip)

Let:

    σ(dst) = s

Compute the local transition:

    (s', outs) = δ_dst(s, ip, v)

where:

    outs = [ (op₁, v₁), ..., (op_k, v_k) ]

Define the updated Global State:

    σ' = σ[ dst ↦ s' ]

Define newly produced Emitted Values:

    E_emit =
        [ (dst, op₁, v₁), ..., (dst, op_k, v_k) ]

Append them to the end of the pending list:

    E' = E_rest ++ E_emit

The resulting Snapshot after this atomic step is:

    (σ', E')

Each atomic step:

- consumes exactly one subscriber of the head emission
- updates exactly one node state
- appends newly emitted values
- produces exactly one new Snapshot

---

## 4. Completion of a Reaction

After all subscribers in Subs(src, op) have been processed,
the head emission (src, op, v) is fully consumed.

At that point, processing continues with the next element
in the pending sequence.

---

## 5. Transition Relation

The small-step transition relation is:

    (σ, (src, op, v) :: E_rest)
        ⇒
    (σ', E')

where σ' and E' are obtained by processing
the next subscriber of (src, op, v).

The full reaction to one emitted value
is the finite sequence of atomic transitions
corresponding to its ordered subscriber list.
