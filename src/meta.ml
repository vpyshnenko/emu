(* meta.ml *)

type index =
  | NodeId
  | OutPortCount
  | InPortCount

let to_int = function
  | NodeId        -> 0
  | OutPortCount  -> 1
  | InPortCount  -> 2


let build ~node_id ~out_port_count ~in_port_count =
  [
    node_id;
    out_port_count;
    in_port_count;
  ]
