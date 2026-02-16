# STEP 3 — Dynamics (Atomic Unfolding Semantics)

This section defines the dynamic semantics of an FSM Network.
Dynamics are defined in terms of atomic snapshot transitions.

Each atomic step:

- processes exactly one subscriber delivery
- updates exactly one node local state
- produces a new network snapshot

---

## 1. Global Configuration

A configuration of the network is a pair:

    (σ, E)

where:

- σ : NodeId → Sₙ  
  is the current global state

- E is a finite ordered list of pending events

Each pending event has the form:

    (src, op, v)

where:

- src ∈ NodeId
- op ∈ OutPorts(src)
- v ∈ Value

---

## 2. Subscriber Order

For each source endpoint (src, op), define:

    Subs(src, op) =
        [ (dst₁, ip₁), (dst₂, ip₂), ..., (dstₘ, ipₘ) ]

where:

    ((src, op), (dstᵢ, ipᵢ)) ∈ R

The order of this list is part of the static network structure.
It defines the order in which subscribers are processed.

This ordering is normative and determines execution order.

---

## 3. Atomic Delivery Step

Let the configuration be:

    (σ, (src, op, v) :: E_rest)

Let (dst, ip) be the next unprocessed subscriber
in Subs(src, op).

If:

    σ(dst) = s

compute the local transition:

    (s', outs) = δ_dst(s, ip, v)

Define updated global state:

    σ' = σ[ dst ↦ s' ]

Only the state of node dst is modified.

---

## 4. Emission Expansion

Let:

    outs = [ (op₁, v₁), ..., (op_k, v_k) ]

For each emission (opᵢ, vᵢ), in order i = 1..k:

    For each routing edge
        ((dst, opᵢ), (n₂, ip₂)) ∈ R
    generate event:
        (dst, opᵢ, vᵢ)

The generated events are appended to the end of E_rest
in the same order in which they are generated.

Denote the resulting list as:

    E_emit

---

## 5. Atomic Transition Rule

The atomic transition is:

    (σ, (src, op, v) :: E_rest)
        ⇒
    (σ', E_rest ++ E_emit)

Each atomic transition:

- processes exactly one subscriber
- updates exactly one node state
- produces exactly one new snapshot

---

## 6. Full Reaction to a Head Event

If:

    Subs(src, op) =
        [ (dst₁, ip₁), ..., (dstₘ, ipₘ) ]

then the reaction to event (src, op, v)
is the sequence of m atomic transitions,
applied in the order of the subscriber list.

Thus a single head event may generate multiple
consecutive snapshots — one per subscriber.

After the last subscriber is processed,
the event (src, op, v) is fully consumed.
