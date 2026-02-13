# 12. Formalization of the Computational Model

This chapter provides a concise formal framing of Emu’s computational model.

The goal is not to introduce additional complexity,
but to state precisely what the system evaluates.

---

## 12.1 Core Sets and Structures

Let:

- N be a finite set of nodes.
- S_i be the finite local state space of node i in N.
- S = Π S_i be the global state space (the product of all local states).
- P be the finite set of ports.
- R ⊆ P × P be the static routing relation.
- E be a FIFO queue of events.

An event is a tuple:

    (src, out_port, payload)

where:

- src ∈ N
- out_port ∈ P
- payload ∈ ℤ

---

## 12.2 Local Transition Functions

For each node i ∈ N, define a deterministic transition function:

    δ_i : S_i × ℤ → S_i × (P × ℤ)* × HaltFlag

Given:

- the current local state of node i
- an incoming payload

the function returns:

- an updated local state
- a finite sequence of emitted events (symbolic port and payload)
- a halt indicator

Each δ_i is deterministic.

---

## 12.3 Global Configuration

A global configuration C consists of:

- A global state S
- A halted flag for each node
- The FIFO event queue E

We write:

    C = (S, Halted, E)

---

## 12.4 One Transition Step

If the queue E is non-empty:

1. Remove the head event:

       e = (src, out_port, payload)

2. Using routing relation R, determine all subscribers:

       Subs = { (dst, in_port) | (src, out_port) → (dst, in_port) ∈ R }

3. For each subscriber (dst, in_port), in deterministic order:

   - If dst is not halted:
       - Apply δ_dst to its local state and payload.
       - Update local state.
       - Append emitted events to the tail of E.
       - Update halted flag if necessary.

This produces a new configuration C'.

We write:

    C → C'

---

## 12.5 Execution

Execution is defined as repeated application of the transition relation:

    C0 → C1 → C2 → ... → Ck

until:

- The event queue E becomes empty, or
- A predefined step bound is reached.

If E becomes empty, the system is quiescent.

---

## 12.6 Compact Summary

Let:

- N be a finite set of nodes.
- E be a FIFO event queue.
- δ_i be deterministic transition functions for each node.

Then execution is:

Repeated application of δ to the head of E,
producing a new state and appending new events to E,
until E is empty.

That is the entire model.
