## Push-Based Reactivity (No Pull, No Addressing)

Emu is push-based by design.

A VM program never "pulls" values from the network and never asks *who* sent something or *who* should receive it. Instead, values are pushed into a node by the evaluator, and any values the node produces are pushed out to the network through its output ports.

### One handler, one input port, one injected value

A handler in Emu is always bound to exactly one input port.

When an event arrives on that port:

- the evaluator selects the corresponding handler program
- the incoming payload is injected automatically into the VM as `regA`
- the handler runs to completion

There is no instruction like:

- "read from input port X"
- "peek the inbox"
- "pull next message"

The only input is the payload that arrives with the event, already placed into `regA`.

This makes the input model explicit and simple: a handler is always a reaction to one specific incoming port.

### No destination addressing inside VM programs

VM programs do not know:

- destination node IDs
- destination input ports
- the topology of the network

They cannot send a message "to node 42" or "to handler 3".

Instead, they only emit to symbolic output ports (streams):

- `Emit` uses a symbolic port index from the stack
- `EmitTo i` emits to symbolic port index `i`
- `EmitIfNonZero i` emits conditionally

From the VM’s perspective, an output port is just a stream where values can be pushed.

### Topology is the developer’s job

The meaning of an output stream is defined outside the VM program, by wiring the network.

It is the developer who decides:

- which node subscribes to which output port
- which input port (handler) receives those values

Once subscribers are connected:

- every emission to an output port becomes a delivered event
- delivery forces the subscribed handler to execute (unless the node is halted)

So the VM program does not "call" other nodes.

It simply emits values, and the topology turns those emissions into forced reactions elsewhere.

### Where Emu’s reactivity comes from

This is the core reactive pattern in Emu:

1. An event arrives and injects a payload into a handler (push in).
2. The handler updates state and emits values to output streams (push out).
3. The network delivers those values to subscribers.
4. Subscriber handlers execute as a consequence.
5. The cascade continues until no events remain.

In other words:

- nodes do not request data
- they react to data arriving
- and their outputs cause further reactions

Emu’s “reactive” nature is not a special subsystem.
It is revealed directly by the push-only semantics of handlers and ports.

### Summary

- Inputs are pushed in by the evaluator (payload in `regA`).
- Programs cannot pull from the network.
- Programs cannot address destinations.
- Programs only push to output streams.
- Topology turns pushes into deliveries.
- Deliveries force subscribed handlers to run.

This separation of concerns is intentional:

- VM programs define local behavior.
- Topology defines influence and causality.
- The evaluator unfolds the consequences.
