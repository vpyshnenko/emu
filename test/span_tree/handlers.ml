open Emu.Instructions
open Layout

let stp_init = [
  (* 1. Set Parent Port to -1 (sentinel indicating "I am Root") *)
  PushConst (-1);
  Store mem.parent_node_id;                 (* RAM <- reset parent_node to #undefined (-1) *)
  Pop;
  
  PushConst 0;
  Store mem.distance;                 (* RAM <- make root distance as 0 *)
  
  PopA;                    (* regA <- 0 *)
  EmitTo output.stp;
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
	  EmitTo output.stp;
    ];
  |];
  Pop;
]

let count_init = [
  Load mem.count;
  GtPop 0;
  BranchOf [|
    [ Halt ]
  |];
  
  PushConst 1;
  Store mem.count;                 
  Pop;
  
  LoadMeta NodeId;
  Load mem.parent_node_id;
  SendTo (output.count, 2);
  
  PushConst 1;
  PopA;
  EmitTo output.count_init;
]

let count = [
  LoadPayload 0;
  LoadMeta NodeId;
  Sub;
  NonEqPop 0;
  BranchOf [|
    [ Halt ]
  |];
  Load mem.parent_node_id;
  EqPop (-1);
  BranchOf [|
    [ 
	  Load mem.count; PushConst 1; Add; Store mem.count; Pop;
	  LoadPayload 1; Load mem.max_node_id; Sub; GtPop 0;
	  BranchOf [| 
	    [ LoadPayload 1; Store mem.max_node_id; Pop; ]
      |];
	];
	[ LoadPayload 1; Load mem.parent_node_id; SendTo (output.count, 2); ]
  |];
]

let handlers = make_handlers ~stp_init ~stp ~count_init ~count