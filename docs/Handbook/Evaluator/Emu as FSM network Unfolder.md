# 4. Emu as an FSM Network Unfolder

At its core, Emu is not merely an executor of programs.  
It is an unfolder of causal behavior.

When you build a network in Emu, you define:

- a set of finite-state machines,
- their local state,
- their transition logic,
- and their topology.

All possible behavior of the system is already encoded in that structure.

What Emu does is unfold it.

---

## Poking the Network

The experimenter provides external input in the form of events.

This is the only external influence on the system.

A single injected event may trigger:

- one state transition,
- a cascade of reactions,
- a feedback loop,
- or stabilization.

The experimenter does not manually step through internal logic.  
They simply poke the network.

Emu handles the rest.

---

## Unfolding the Reaction Chain

Once an event is injected, Emu:

1. Delivers it to the appropriate node.
2. Executes the corresponding handler.
3. Updates local state.
4. Collects emitted events.
5. Enqueues those events.
6. Repeats the process.

This continues until no events remain.

The resulting cascade is not invented by Emu.  
It is revealed by it.

The structure, rules, and topology determine the outcome.  
Emu simply applies them deterministically.

---

## Deterministic Causal Evolution

Every unfolding follows strict rules:

- events are processed in FIFO order,
- handlers execute deterministically,
- topology is fixed,
- no hidden scheduler intervenes.

Given the same initial state and the same injected events, the unfolding will always be identical.

The network behaves like a causal machine whose reactions are fully reproducible.

---

## Recording the Evolution

Emu does not only unfold behavior — it records it.

After each transition, the complete system state can be captured:

- node states,
- event queue,
- halted flags,
- topology.

This produces a sequence of immutable snapshots.

The unfolding becomes inspectable.

You can:

- trace causal chains,
- analyze transitions,
- replay scenarios,
- branch from intermediate states.

The history is not lost.  
It is preserved.

---

## Behavior as Latent Structure

In this view, behavior is not something that happens spontaneously.

It is latent in:

- the nodes,
- the wiring,
- the transition rules.

Emu makes this latent behavior visible.

The experimenter injects stimuli.  
The network reacts.  
Emu unfolds and records the consequences.

---

## A Precise Summary

Emu is a deterministic engine that unfolds and records the causal evolution of finite-state machine networks in response to external events.

It does not simulate time.  
It does not model concurrency.  
It does not introduce randomness.

It simply reveals the transition history that is already encoded in the structure of the system.
