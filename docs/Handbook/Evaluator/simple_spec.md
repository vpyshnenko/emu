If We Rewrite Emu in Pure Form

## Engine definition:

Given:

    Nodes : NodeId → State
    δ     : NodeId → (State × InPort × Value → State × List(Event))
    R     : routing
    Q     : queue

Repeat:

    (src, op, v) = dequeue(Q)

    for each (dst, in_p) in R(src, op):

        (state', outs) = δ(dst)(Nodes(dst), in_p, v)

        Nodes(dst) := state'

        for each e in outs:
            enqueue(Q, e)

