open Emu.Instructions

type mem = {
  parent_node_id: int;
  distance: int;
}

let init_in = 0
let stp_in = 1

let stp_out = 0

let mem = { parent_node_id = 0; distance = 1 }


let init = [
  (* 1. Set Parent Port to -1 (sentinel indicating "I am Root") *)
  PushConst (-1);
  Store mem.parent_node_id;                 (* RAM <- reset parent_node to #undefined (-1) *)
  Pop;
  
  PushConst 0;
  Store mem.distance;                 (* RAM <- make root distance as 0 *)
  
  PopA;                    (* regA <- 0 *)
  EmitTo stp_out;
]

let stp = [
  (* 1. Calculate proposed_dist = incoming distance + 1 *)
  PushA;
  
  PushConst 1;
  Add;
  
  (* 2. Compare proposed_dist with current_dist *)
  Dup;
  Load mem.distance;                  (* Stack: [current_dist; proposed_dist ] *)
  Sub;
  LtPop 0;                    (* 0 (True) if proposed < current *)
  
  BranchOf [|
    (* --- UPDATE BRANCH --- *)
    [
      LoadMeta SenderNodeId;
	  Store mem.parent_node_id;
	  Pop;
	  
      Store mem.distance;
	  
      PeekA;
	  EmitTo stp_out;
    ];
  |];
  Pop;
]