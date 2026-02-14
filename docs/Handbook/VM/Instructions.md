# Instructions

The Emu Virtual Machine executes a compact, fixed instruction set.

Instructions are designed to be:

- minimal
- deterministic
- easy to reason about
- sufficient to express state transitions and event emission

All instructions operate within the VM sandbox of a single node.

---

## Instruction semantics (as implemented)

This section describes the exact semantics implied by `vm.ml`.

### Stack operations

- `PushConst n`  
  Pushes `n` onto the stack.

- `Pop`  
  Pops one value and discards it.

- `Add`  
  Pops `a`, then pops `b`, then pushes `a + b`.  
  (Note: order matters only for non-commutative operations; `Add` is symmetric.)

- `AddMod`  
  Uses the stack in a very specific shape:

  - Pops `input`
  - Pops `acc`
  - Peeks `ceil` (does not pop it)
  - Computes `sum = acc + input`

  Then pushes two values:

  - pushes `sum` (or `sum - ceil`)
  - pushes overflow flag (`0` if no overflow, `1` if overflow)

  Concretely:

  - if `sum < ceil`: push `sum`, then push `0`
  - else: push `(sum - ceil)`, then push `1`

  This design is intentional: the overflow flag can be inspected without losing the sum.

- `LogStack`  
  Prints stack contents for debugging and returns the unchanged stack.

### Accumulator register A

`regA` is initialized from the incoming payload and can be used as a lightweight register.

- `PushA`  
  Pushes current `regA` onto the stack.

- `PopA`  
  Pops top-of-stack into `regA`.

- `PeekA`  
  Copies top-of-stack into `regA` (without popping).

### Persistent RAM (`mem`)

- `Load i`  
  Pushes `mem[i]` onto stack. Bounds checked.

- `Store i`  
  Writes `mem[i] := peek(stack)` (does NOT pop). Bounds checked.

This is a subtle but important choice: `Store` keeps the value on the stack, which makes update patterns compact but also means the stack can grow unless the program pops intentionally.

### Metadata RAM (`meta_mem`)

- `LoadMeta m`  
  Converts meta index to integer and pushes `meta_mem[i]`. Bounds checked.

Metadata is read-only from the VM perspective.

### Emission

All emission instructions send the current content of `regA` as payload.

- `Emit`
  - Uses `peek(stack)` as the *symbolic* output port index.
  - Does not pop it.
  - Emits `(idx, regA)`.

- `EmitTo idx`
  - Emits `(idx, regA)`.

- `EmitIfNonZero idx`
  - If `peek(stack) != 0`, emits `(idx, regA)`.
  - Does not pop the condition.

All emission instructions validate `idx` against `out_port_count`.

---

## Control instructions

Control instructions do not modify state directly. They affect termination.

- `Halt`  
  Stops execution immediately.

- `HaltIfEq (n, x)`  
  Reads the n-th element from the stack (0 = top).  
  If equal to `x`, stops execution; otherwise continues.

Important: `get_nth` is implemented by repeatedly popping a copy of the stack, so it does not mutate the real stack, but it is O(n) and will raise underflow if stack is too short.

---

## Program termination conditions

A handler finishes in one of four ways:

1. `Halt` encountered -> returns `halted = true`
2. `HaltIfEq` triggers -> returns `halted = true`
3. PC goes out of bounds -> returns `halted = false`
4. Step limit exceeded -> raises runtime error

In practice, well-formed handlers should terminate explicitly via `Halt` / `HaltIfEq`
(or rely on running off the end of code, if you treat that as a normal return).

---

## Execution Guarantees

All instructions:

- are deterministic
- have no side effects outside the node
- operate within bounded stack and memory
- are executed sequentially

Errors (such as stack underflow or out-of-bounds access) cause immediate failure.

---

## Design Philosophy

The instruction set is intentionally small.

It is designed to:

- express state transitions
- enable conditional emission
- support modular arithmetic patterns
- remain easy to teach
- remain easy to reason about

The power of Emu comes not from complex instructions,
but from how simple instructions interact across a network.
