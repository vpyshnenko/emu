(* router.ml *)

open Emu
open Emu.Instructions

module IntMap = Map.Make(Int)

(* Define separate types for input and output port structures *)
type router_state = {
  flag: int; (* (-1) uninitialized; (0) - leaf; (1) - non-leaf *)
  value: int;
  count: int;
}

type router_input = {
  data: int;
  flush: int;
  reset: int;
  flush_lt_complete: int;
  flush_gt_complete: int;
}

type router_output = {
  data_lt: int;
  data_gt: int;
  
  flush_lt: int;
  flush_gt: int;
  flush_complete: int;
  
  out: int;
  reset: int;
}

type t = {
  node: Node.t;
  id : int;
  input : router_input;
  output : router_output;
}

let input = {
  data = 0;
  flush = 1;
  reset = 2;
  flush_lt_complete = 3;
  flush_gt_complete = 4;
}

let output = { 
  data_lt = 0;
  data_gt = 1;
  flush_lt = 2;
  flush_gt = 3;
  flush_complete = 4;
  out = 5;
  reset = 6;
}

let out_ports = List.init 7 Fun.id

let state = { flag = (-1); value = (-1); count = (-1) }
let initial_state = [state.flag; state.value; state.count]

let data_handler = [
  Load 0; Eq (-1); (* check noninit flag *)
  BranchOf [|
    [ 
	  PushConst 0; Store 0; (* set init flag as leaf *)
	  PushA; Store 1;  (* store value *)
	  PushConst 1; Store 2;  (* init counter *)
	  Halt;
	]
  |];
  Load 1; PushA; Sub;  Eq 0; (* compare with cur value *)
  BranchOf [|
   [ Load 2; PushConst 1; Add; Store 2; Halt ];(* if the same then inc counter *)
   [
     Gt 0; BranchOf [|
	  [ EmitTo output.data_lt];  (* forward to "less than" child *)
	  [ EmitTo output.data_gt]; (* forward to "greater than" child *)
	 |];
	 PushConst 1; Store 0; (* set non-leaf flag *)
   ]
 |]
]

let flush_handler = [
  Load 0; Eq 0; (* check is leaf *)
  BranchOf [|
    [
	  Load 1; PopA; (* load cur value in regA *)
	  Load 2; (* load counter *)
	  PushConst 1; (* force entry to loop body *)
	  Loop [
	    EmitTo output.out;
        PushConst 1; Sub; 
        Eq 0
	  ];
	  PushConst 1; PopA; EmitTo output.flush_complete;
	];
	[ EmitTo output.flush_lt ];
  |]
]
let flush_lt_complete_handler = [
  Load 1; PopA;
  Load 2; Eq 0;
  Loop [
    EmitTo output.out;
    PushConst 1; Sub; 
    Eq 0
 ];
 PushConst 1; PopA; EmitTo output.flush_gt;
]

let flush_gt_complete_handler = [
  EmitTo output.flush_complete
]

let reset_handler = [
  PushConst (-1);
  Store 0; Store 1; Store 2;
  EmitTo output.reset
]

let handlers = IntMap.empty
  |> IntMap.add input.data data_handler
  |> IntMap.add input.flush flush_handler
  |> IntMap.add input.flush_lt_complete flush_lt_complete_handler
  |> IntMap.add input.flush_gt_complete flush_gt_complete_handler
  |> IntMap.add input.reset reset_handler

let vm = Vm.create ~stack_capacity:30 ~max_steps:100 ~mem_size:3

let make ~id : t =
  let node = Node.create 
      ~id 
      ~state:initial_state 
      ~vm 
      ~handlers
      ~out_ports 
      ()
  in
  { id; node; input; output }
	  
	  


