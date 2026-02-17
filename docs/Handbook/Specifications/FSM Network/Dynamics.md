# STEP 3 — Dynamics (Atomic Unfolding Semantics)

This section defines the dynamic semantics of an FSM Network.

The evolution of the network is described in terms of:

- Global State
- Pending Events
- Snapshot
- Atomic transition rule

---

## 1. Global State

A Global State is a mapping:

    σ : NodeId → Sₙ

For each node n ∈ N:

    σ(n) ∈ Sₙ

A Global State represents the intrinsic state of all nodes in the network.

---

## 2. Pending Event Sequence

A Pending Event Sequence is a finite ordered list:

    E = [ e₁, e₂, ..., e_k ]

Each event has the form:

    (src, op, v)

where:

- src ∈ NodeId
- op ∈ OutPorts(src)
- v ∈ Value

The order of this sequence determines which event is processed next.

---

## 3. Snapshot

A Snapshot is a pair:

    Snapshot = (σ, E)

where:

- σ is a Global State
- E is a Pending Event Sequence

A Snapshot represents the complete dynamic state of the network.

---

## 4. Subscriber Order

For each source endpoint (src, op), define the ordered subscriber list:

    Subs(src, op) =
        [ (dst₁, ip₁), (dst₂, ip₂), ..., (dst_m, ip_m) ]

such that:

    ((src, op), (dstᵢ, ipᵢ)) ∈ R

The order of Subs(src, op) is part of the static structure
and determines delivery order.

---

## 5. Atomic Delivery Step

Let the current Snapshot be:

    (σ, (src, op, v) :: E_rest)

Let (dst, ip) be the first unprocessed subscriber
in Subs(src, op).

Let:

    σ(dst) = s

Compute:

    (s', outs) = δ_dst(s, ip, v)

Define updated Global State:

    σ' = σ[ dst ↦ s' ]

Only the state of node dst is modified.

---

## Emission Expansion (Net-Level Out-Events)

Let the local transition of the delivered-to node be:

    (s', outs) = δ_sub(s, ip, v)

where:

    outs = [ (op₁, v₁), ..., (op_k, v_k) ]

Each element (opᵢ, vᵢ) is an emission produced by node sub
on its output port opᵢ.

These emissions are converted into pending out-events by tagging
the emitting node as the event source:

    E_emit = [ (sub, op₁, v₁), ..., (sub, op_k, v_k) ]

The pending event sequence is updated by appending E_emit to E_rest:

    E' = E_rest ++ E_emit


---

## 7. Atomic Transition Rule

The atomic unfolding step is:

    (σ, (src, op, v) :: E_rest)
        ⇒
    (σ', E')

Each atomic transition:

- processes exactly one subscriber
- updates exactly one node-local state
- produces exactly one new Snapshot

---

## 8. Full Reaction to a Head Event

If:

    Subs(src, op) =
        [ (dst₁, ip₁), ..., (dst_m, ip_m) ]

then the complete reaction to event (src, op, v)
is the sequence of atomic transitions,
applied in subscriber order.

After the final subscriber is processed,
the event is removed from the Pending Event Sequence.
