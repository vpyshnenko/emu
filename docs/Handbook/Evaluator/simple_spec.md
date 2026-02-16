If We Rewrite Emu in Pure Form

## Engine definition:

Given:
    Nodes : NodeId → State
    δ     : NodeId → (State × InPort × Value → State × List(Event))
    R     : routing
    Q     : queue

Repeat:
    (src,op,v) = dequeue
    for each (dst,in_p) in R(src,op):
        (state', outs) = δ(dst)(state(dst), in_p, v)
        update state(dst)
        enqueue outs
