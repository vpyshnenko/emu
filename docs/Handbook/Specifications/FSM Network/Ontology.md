# STEP 1 — Ontology of an FSM Network

This section defines the entities that exist in the FSM Network domain.

---

## 1. Primitive Domains

The following primitive sets exist:

- **NodeId** — identifiers of nodes
- **InPortId** — identifiers of input ports
- **OutPortId** — identifiers of output ports
- **Value** — values carried by events
- **State** — local node states

---

## 2. Core Entities

### 2.1 Node

A **Node** is an entity characterized by:

- a unique **NodeId**
- a local **State**
- a collection of input ports identified by **InPortId**
- a collection of output ports identified by **OutPortId**

---

### 2.2 Input Port

An **Input Port** is an entity identified by an **InPortId** and associated with a specific node.

---

### 2.3 Output Port

An **Output Port** is an entity identified by an **OutPortId** and associated with a specific node.

---

### 2.4 Event

An **Event** is an entity consisting of:

- a destination **NodeId**
- a destination **InPortId**
- a **Value**

An event represents a value delivered to a node at a specific input port.

---

### 2.5 Emission

An **Emission** is an entity consisting of:

- a source **NodeId**
- a source **OutPortId**
- a **Value**

An emission represents a value produced by a node at a specific output port.

---

### 2.6 Network

A **Network** is an entity composed of:

- a finite set of **Nodes**
- a connectivity relation between output ports and input ports

---

### 2.7 Snapshot

A **Snapshot** is an entity consisting of:

- an assignment of a **State** to each **NodeId**

A snapshot represents a global configuration of node-local states.
