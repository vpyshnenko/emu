# 9. Avalanches and Cascades

In Emu, a single external event can trigger a chain reaction.

That chain reaction is called an avalanche.

An avalanche is not a special feature.  
It is the natural consequence of causal propagation in a connected network.

---

## 9.1 What Is a Cascade?

A cascade begins when:

- An event is injected into the system, or
- A handler emits an event.

That event may cause:

- A state transition in one node,
- Which emits new events,
- Which trigger additional transitions,
- Which emit more events,
- And so on.

This chain continues until no events remain in the queue.

That entire unfolding is a cascade.

---

## 9.2 What Is an Avalanche?

In Emu terminology:

An avalanche is the complete processing of the event queue
starting from one injected external event,
continuing until the system reaches quiescence.

In other words:

Inject one event.
Process everything it causes.
Stop when the queue becomes empty.

This gives a clean conceptual boundary around a reaction.

---

## 9.3 Quiescent State

The system is quiescent when:

- The global event queue is empty.

Quiescence does not imply stability in a mathematical sense.
It simply means no further reactions are pending.

A new external event may start another avalanche.

---

## 9.4 Why Avalanches Matter

Avalanches reveal structural properties of the network:

- Feedback loops
- Oscillations
- Stabilization behavior
- Runaway growth
- Backpressure effects
- Termination conditions

They expose how local rules combine into global behavior.

You do not simulate time.
You observe causal propagation until exhaustion.

---

## 9.5 Finite vs Non-Terminating Avalanches

Avalanches can be:

### Finite

The queue eventually becomes empty.

This is the normal and desirable case.

### Non-terminating

If handlers continually emit events without reaching a stopping condition,
the queue will never empty.

In this case, execution continues indefinitely
(or until a configured step limit is reached).

Emu does not assume termination.
It evaluates until quiescence or until limits are exceeded.

---

## 9.6 Feedback Loops

Cycles in topology naturally create the possibility of cascades.

For example:

Node A emits to Node B.
Node B emits back to Node A.

If their handlers continue emitting,
a loop forms.

Such loops may:

- Stabilize
- Oscillate
- Grow without bound
- Halt explicitly

Avalanches make these dynamics visible.

---

## 9.7 Deterministic Cascades

Even complex cascades remain deterministic.

Because:

- The queue is FIFO,
- Subscriber order is fixed,
- Handlers are deterministic,
- There is no concurrency.

Given identical initial conditions,
the avalanche will always unfold identically.

This makes cascades analyzable rather than chaotic.

---

## 9.8 Controlled Exploration

Because avalanches are deterministic and recorded through snapshots,
you can:

- Inspect each step of the cascade,
- Analyze the exact order of reactions,
- Identify the transition that caused instability,
- Replay the avalanche repeatedly.

This turns potentially complex network behavior
into something structured and inspectable.

---

## 9.9 Summary

An avalanche is the full causal unfolding of the system
triggered by a single injected event.

It continues until no events remain.

Avalanches reveal:

- The dynamic structure of the network,
- The effects of feedback,
- The presence of stabilization or divergence,
- The true consequences of local transition rules.

They are not simulated time.
They are deterministic causal propagation.
