# STEP 1 — Ontology of a Deterministic Network of Reactive State Machines

This section defines the entities that exist in the domain model.

---

## 1. Primitive Domains

The following primitive sets exist:

- **NodeId** — identifiers of reactive state machines
- **InPortId** — identifiers of input ports
- **OutPortId** — identifiers of output ports
- **Value** — values carried through the network
- **State** — local states of reactive machines

---

## 2. Core Entities

### 2.1 Reactive State Machine (Node)

A **Reactive State Machine** (Node) is an entity characterized by:

- a unique **NodeId**
- a local **State**
- a collection of input ports identified by **InPortId**
- a collection of output ports identified by **OutPortId**

---

### 2.2 Input Port

An **Input Port** is an entity identified by an **InPortId**
and associated with a specific node.

---

### 2.3 Output Port

An **Output Port** is an entity identified by an **OutPortId**
and associated with a specific node.

---

### 2.4 Emitted Value (Out-Event)

An **Emitted Value** is an entity consisting of:

- a source **NodeId**
- a source **OutPortId**
- a **Value**

This entity is written as:

    (src, op, v)

and represents a value emitted by a node at a specific output port.

---

### 2.5 Delivered Event

A **Delivered Event** is an entity consisting of:

- a destination **NodeId**
- a destination **InPortId**
- a **Value**

This entity is written as:

    (dst, ip, v)

and represents the delivery of a value to a node at a specific input port.

---

### 2.6 Network

A **Network** is an entity composed of:

- a finite set of Reactive State Machines (Nodes)
- a connectivity relation between output ports and input ports

---

### 2.7 Global State

A **Global State** is an entity consisting of:

- an assignment of a **State** to each **NodeId**

This entity is written as a mapping:

    σ : NodeId → State

---

### 2.8 Snapshot

A **Snapshot** is an entity consisting of:

- a Global State
- a finite ordered list of pending Emitted Values

This entity is written as:

    Snapshot = (σ, E)

where E is a list of Emitted Values (Out-Events).
