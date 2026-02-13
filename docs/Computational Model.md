# 5. Computational Model

This chapter defines the abstract computation model implemented by Emu.

The goal is to describe what exists and how computation is defined, independent of implementation details, while capturing the essential role of the virtual machine.

---

## 5.1 Core Entities

An Emu system consists of:

1. Nodes
2. A deterministic Virtual Machine (VM)
3. Local State
4. Ports
5. Events
6. Topology
7. Event Queue

These elements define the universe in which computation occurs.

---

## 5.2 Nodes and the Virtual Machine

### Nodes

A node is a finite-state machine whose transitions are defined by programs executed on a deterministic stack-based virtual machine.

Each node contains:

- Persistent local state (a finite list of integers)
- A finite set of input ports
- A finite set of output ports
- A handler program for each input port

Nodes do not share memory.  
All interaction occurs through events.

---

### The Virtual Machine

Each handler is a small program executed by Emu’s internal VM.

The VM provides:

- A bounded stack
- Access to the node’s local state (RAM)
- Access to metadata (e.g., port counts, node ID)
- Deterministic instruction semantics
- The ability to emit events
- The ability to halt

The VM is deterministic:

Given the same input, state, and memory, it will always produce the same result.

The VM defines how a node reacts to an event.

---

## 5.3 Local State

Each node maintains private persistent state.

State:

- Survives across events
- Is accessible only to the node’s VM program
- Can be read and updated during handler execution

The global system state includes the local state of all nodes.

---

## 5.4 Ports

Ports define communication structure.

- Input ports receive events.
- Output ports emit events.

Ports are statically defined and do not change during execution.

---

## 5.5 Events

An event consists of:

- A source node
- An output port
- An integer payload

Events are the only mechanism of influence between nodes.

They do not carry time.
They represent causal triggers.

---

## 5.6 Topology

Topology defines how output ports connect to input ports.

It is:

- Static
- Explicit
- Deterministic

When a node emits an event on an output port, the topology determines which input ports receive it.

Topology does not change during execution.

---

## 5.7 Event Queue

The system maintains a global FIFO event queue.

Events are:

- Enqueued when emitted by the VM
- Dequeued in order
- Delivered to subscribed nodes

The queue represents pending causal influence.

---

## 5.8 System State

At any moment, the complete system state consists of:

- The local state of all nodes
- The contents of the event queue
- The halted status of nodes

This state fully determines future evolution.

There is no hidden scheduler.
There is no implicit timing mechanism.

---

## 5.9 Transitions

A transition occurs when:

1. The next event is dequeued.
2. The event is delivered to all subscribed input ports.
3. For each delivery, the corresponding node’s handler program executes on the VM.
4. The VM may update local state.
5. The VM may emit new events, which are enqueued.

Each such delivery constitutes one causal step.

Transitions are driven entirely by VM execution.

---

## 5.10 Evaluation to Quiescence

Execution proceeds by repeatedly applying transitions until:

- The event queue becomes empty, or
- A stopping condition (e.g., halt) is reached.

When no events remain, the system is in a quiescent state.

Quiescence means no further reactions are pending.

---

## 5.11 Determinism

The computational model is deterministic.

Given:

- The same initial node states
- The same topology
- The same injected external events

The sequence of transitions and the final system state will always be identical.

Determinism is guaranteed by:

- Static topology
- FIFO event ordering
- Deterministic VM semantics
- Absence of concurrency
- Absence of randomness

---

## 5.12 Summary

Emu implements a deterministic, event-driven computation model for statically wired networks of finite-state machines whose transitions are defined by programs executed on a stack-based virtual machine.

Computation consists of unfolding causal transitions in response to external events until no further reactions remain.

The full evolution of the system is determined entirely by:

- Node definitions (VM programs)
- Topology
- Initial state
- Injected events
