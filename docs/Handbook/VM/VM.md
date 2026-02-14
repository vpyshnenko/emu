# VM

## A tiny machine inside every node

Each node in Emu contains a small, purpose-built virtual machine: a compact execution engine designed specifically for event-driven state transitions.

The VM is intentionally minimal:

- a stack
- a small instruction set
- deterministic execution
- no concurrency
- no time
- no side effects outside the node

This simplicity is what makes Emu predictable, teachable, and easy to debug.

---

## Why a VM at all?

A node needs a precise, uniform way to react to incoming values.

In Emu, a handler is not “just a function call”. It is a tiny program: a scripted description of how the node should respond to an event. The VM provides:

- a controlled, sandboxed environment
- deterministic execution (same input and state -> same result)
- a uniform representation of behavior (handlers are bytecode)
- a natural place for tracing and replay
- a safe target for student code

The VM is the mechanism that turns an incoming event into:

- local state changes
- emitted events
- optional halting of the node

---

## VM runtime state

When a node receives an event, Emu constructs a fresh VM runtime instance for that handler execution.

### Persistent vs ephemeral components

Persistent (stored in the node across events):

- **node state**: `State.t` (int list) persisted across handler calls

Ephemeral (created per handler execution):

- **stack**: starts empty on each handler call
- **program counter (pc)**: starts at 0
- **step counter**: starts at 0 (bounded by `max_steps`)
- **regA accumulator**: initialized from incoming payload

### Memory spaces

The VM sees two memory arrays:

1. **mem** (persistent RAM)
   - Created from the node state list (padded with zeros up to `mem_size`)
   - Mutated by `Store`
   - Packed back to a state list when the handler finishes

2. **meta_mem** (read-only metadata)
   - Created from `Meta.build`
   - Accessible via `LoadMeta`
   - Currently contains:
     - `NodeId`
     - `OutPortCount`
     - `InPortCount`

### Output buffer

During execution, emissions are collected into an output list:

- Each emission is `(symbolic_out_port_index, payload_value)`
- Payload is always taken from `regA` at the moment of emission
- Output list is returned to the node layer after program termination

---

## Handler execution lifecycle

Given:

- node persistent state `state : int list`
- metadata list `meta_info : int list`
- handler bytecode `code : instr list`
- incoming payload `payload : int`
- `out_port_count : int`

The VM performs:

1. Convert `state` into `mem : int array` of length `mem_size`
2. Convert `meta_info` into `meta_mem : int array`
3. Initialize `regA := payload`
4. Initialize empty stack with capacity `stack_capacity`
5. Execute instructions sequentially until:
   - `Halt` is reached, or
   - `HaltIfEq` triggers a halt, or
   - program counter goes out of bounds, or
   - `max_steps` is exceeded (error)

Returns:

- new persistent state (RAM packed back into list)
- list of emitted outputs `(sym_idx, value)`
- halted flag (whether `Halt` / `HaltIfEq` terminated execution)

---

## Deterministic, single-threaded execution

A handler execution is single-threaded and non-preemptive:

- one instruction at a time
- no concurrency
- no scheduling
- no interleaving
- no nondeterminism

Given identical `state`, `meta_mem`, `payload`, and `code`,
the VM result is identical.

This makes handler behavior testable, replayable, and easy to reason about.

---



## Outputs and ordering notes

Within a single instruction execution (`exec_instr`):

- each instruction returns a list of outputs emitted by that instruction only
- emissions are collected into a per-instruction list using cons, so per-instruction output order is reversed (usually only 0 or 1 emission per instruction)

Across the whole program (`exec_program`):

- outputs are accumulated as `outputs := outs @ outputs`
- combined with the per-instruction consing, the final output list ends up in a "chronological" order for typical instruction patterns (especially when emitting one event per instruction)
- if you emit multiple times in one instruction in the future, be careful: list construction order will matter

At the VM level, outputs are still *symbolic port indices*. They become real network ports at the Node layer.

---

## VM configuration

The VM is configured per node:

- `stack_capacity` limits stack growth (overflow is an error)
- `mem_size` fixes RAM size (node state is padded to this size)
- `max_steps` prevents non-terminating handlers (exceeding it is an error)

This ensures the VM is bounded and safe to use for experimentation and education.

---

## In one sentence

The Emu VM is a tiny, deterministic stack machine that executes per-port handler programs: it consumes an injected payload through `regA`, reads/writes persistent node state via `mem`, optionally consults read-only metadata via `meta_mem`, emits symbolic events, and returns the updated state plus emitted outputs.
