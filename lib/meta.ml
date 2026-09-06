(* meta.ml *)

type index =
  | NodeId
  | OutPortCount
  | InPortCount
  | SenderNodeId
  | CurInPort
  | MemLen

let to_int = function
  | NodeId        -> 0
  | OutPortCount  -> 1
  | InPortCount  -> 2
  | CurInPort     -> 3
  | SenderNodeId  -> 4
  | MemLen  -> 5


let build ~node_id ~out_port_count ~in_port_count ~cur_in_port ~sender_node_id ~mem_len =
  [
    node_id;
    out_port_count;
    in_port_count;
	cur_in_port;
	sender_node_id;
	mem_len
  ]
