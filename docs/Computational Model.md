# 5. Computational Model

This chapter defines the abstract computation model implemented by Emu.

The goal is to describe *what exists* and *how computation is defined*, independent of implementation details.

---

## 5.1 Core Entities

An Emu system consists of:

1. **Nodes**
2. **Local State**
3. **Ports**
4. **Events**
5. **Topology**
6. **Event Queue**

These form the universe in which computation occurs.

---

### Nodes

A node is a finite-state machine.

Each node contains:

- Persistent local state (a finite list of integers)
- A finite set of input ports
- A finite set of output ports
- A deterministic handler for each input port

Nodes do not share memory.  
All interaction occurs through events.

---

### Local State

Each node maintains private state.

State:

- Is persistent across events
- Is updated only by the node’s handler
- Is not directly accessible by other nodes

The global system state is the collection of all node states.

---

### Ports

Ports define communication structure.

- Input ports receive events.
- Output ports emit events.

Ports are statically defined and do not change at runtime.

---

### Events

An event consists of:

- A source node
- An output port
- An integer payload

Events are the only mechanism of influence between nodes.

Events do not carry time.
They represent causal triggers.

---

### Topology

Topology defines how output ports connect to input ports.

It is:

- Static
- Explicit
- Deterministic

When a node emits an event on an output port, the topology determines which input ports receive it.

Topology does not change during execution.

---

### Event Queue

The system maintains a global FIFO event queue.

Events are:

- Enqueued when emitted
- Dequeued in order
- Delivered to subscribed nodes

The queue represents pending causal influence.

---

## 5.2 System State

At any moment, the complete system state consists of:

- All node states
- The event queue
- Halted status of nodes

This state fully determines future evolution.

There is no hidden scheduler.
There is no implicit timing mechanism.

---

## 5.3 Transitions

A transition occurs when:

1. The next event is dequeued.
2. The event is delivered to all subscribed input ports.
3. Each corresponding handler executes deterministically.
4. Node state may be updated.
5. New events may be emitted and enqueued.

Each such delivery constitutes one causal step.

---

## 5.4 Evaluation to Quiescence

Execution proceeds by repeatedly applying transitions until:

- The event queue becomes empty, or
- A global stopping condition is reached.

When no events remain, the system is in a quiescent state.

Quiescence does not imply stability in a mathematical sense.  
It simply means no further reactions are pending.

---

## 5.5 Determinism

The computational model is deterministic.

Given:

- The same initial node states
- The same topology
- The same sequence of injected external events

The resulting sequence of transitions and final state will always be identical.

There is:

- No concurrency
- No nondeterministic scheduling
- No randomization

All behavior is fully determined by structure and inputs.

---

## 5.6 External Interaction

Computation begins only when external events are injected.

An experimenter may:

- Inject events
- Observe snapshots
- Inspect final state

After injection, the system unfolds causally according to its rules.

---

## 5.7 Summary

Emu implements a deterministic, event-driven computation model for statically wired networks of finite-state machines.

Computation consists of unfolding causal transitions in response to external events until no further reactions remain.

The full evolution of the system is determined entirely by:

- Node definitions
- Topology
- Initial state
- Injected events
