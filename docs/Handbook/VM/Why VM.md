## Why a VM?

Emu is not built on top of a general-purpose runtime for node behavior.

Each node contains a purpose-built virtual machine.

This is intentional.

Emu needs a controllable execution environment that is:

- deterministic
- bounded
- inspectable
- portable
- aligned with the computational model

Using a general-purpose language runtime would introduce unnecessary complexity and weaken these guarantees.

---

### 1. Lightweight and Focused

General runtimes (Python, Java, etc.) include:

- threads
- asynchronous scheduling
- exceptions
- dynamic memory allocation
- I/O primitives
- reflection
- global state

Emu does not need any of that.

The VM implements only what is required:

- stack
- bounded RAM
- deterministic arithmetic
- event emission
- explicit termination

This keeps the runtime small, fast, and conceptually clean.

---

### 2. Determinism by Construction

General languages allow:

- random number generation
- time access
- global mutable state
- concurrency
- nondeterministic scheduling

Even if you *intend* to avoid them, the runtime does not enforce it.

The Emu VM enforces determinism structurally:

- no access to time
- no randomness
- no threads
- no blocking calls
- no external I/O
- no hidden scheduler

The instruction set makes nondeterminism impossible unless explicitly modeled in state.

---

### 3. FSM-Network-Oriented Instruction Set

The VM is not a generic computation engine.

It is designed specifically for communicating finite-state machines.

The instruction set includes primitives that directly support:

- persistent node state (`Load`, `Store`)
- metadata inspection (`LoadMeta`)
- multi-port emission (`Emit`, `EmitTo`)
- conditional emission (`EmitIfNonZero`)
- lifecycle control (`Shutdown`, etc.)

These concepts do not map cleanly to standard function semantics.

Embedding them directly into the instruction set makes node behavior:

- explicit
- uniform
- easy to analyze

---

### 4. Bounded Execution

Each handler execution is bounded by:

- stack capacity
- memory size
- instruction step limit

This prevents:

- runaway recursion
- infinite loops inside a single handler
- stack overflow
- unbounded resource growth

In general-purpose runtimes, such limits must be enforced externally.

In Emu, they are part of the model.

---

### 5. Safe Sandbox

The VM provides a sandbox for:

- educational use
- experimentation
- student-written handlers

Handlers cannot:

- access the filesystem
- spawn threads
- allocate arbitrary objects
- mutate global state
- call external libraries

This makes Emu safe for teaching and controlled experimentation.

---

### 6. Uniform Traceability

Because the VM is small and deterministic:

- every instruction can be traced
- stack evolution can be logged
- state transitions are explicit
- emissions are observable

This would be much harder with full host-language semantics.

The VM acts as a microscope for node behavior.

---

### 7. Portability

The VM instruction set is:

- small
- self-contained
- implementation-agnostic

It can be reimplemented in:

- OCaml
- Rust
- C
- JavaScript
- embedded environments
- even hardware

The computational model remains identical.

The VM defines a portable semantic core.

---

### 8. Clear Separation of Concerns

Using a VM enforces architectural boundaries:

- VM defines local transition semantics.
- Node layer handles symbolic-to-actual port mapping.
- Network layer handles routing.
- Evaluator handles event propagation.

If handlers were just arbitrary functions, these boundaries would blur.

---

### 9. Conceptual Clarity

A VM makes the computational model explicit.

Handlers are not arbitrary code.
They are transition scripts.

This strengthens the identity of Emu as:

- a deterministic execution engine
- for networks of finite-state machines
- with explicit transition semantics

---

## Summary

Emu uses a purpose-built VM because it needs:

- strict determinism
- bounded execution
- network-oriented primitives
- lifecycle control
- sandbox safety
- full traceability
- portability across platforms

A general-purpose runtime would be more powerful,
but less controlled.

Emu chooses clarity and control over generality.
