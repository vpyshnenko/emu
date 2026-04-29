(* router.ml *)

open Emu
open Emu.Instructions

module IntMap = Map.Make(Int)

(* Define separate types for input and output port structures *)
type router_state = {
  flag: int; (* (-1) uninitialized; (0) - initialized;  *)
  value: int;
}

type router_input = {
  data: int;
  reset: int;
}

type router_output = {
  data_lt: int;
  data_gt: int;
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
  reset = 1;
}

let output = { 
  data_lt = 0;
  data_gt = 1;
  out = 2;
  reset = 3;
}

let out_ports = List.init 4 Fun.id

let state = { flag = (-1); value = (-1) }
let initial_state = [state.flag; state.value]

let data_handler = [
  Load 0; Eq (-1); (* check noninit flag *)
  BranchOf [|
    [ 
	  PushConst 0; Store 0; (* set init flag as leaf *)
	  PushA; Store 1;  (* store value *)
	  EmitTo output.out;
	  Halt
	]
  |];
  Load 1; PushA; Sub;  Eq 0; (* compare with cur value *)
  BranchOf [|
   [ Halt ];(* if the same as basic value then do nothing *)
   [
     Gt 0; BranchOf [|
	  [ EmitTo output.data_lt];  (* forward to "less than" child *)
	  [ EmitTo output.data_gt]; (* forward to "greater than" child *)
	 |];
   ]
 |]
]


let reset_handler = [
  PushConst (-1);
  Store 0; Store 1;
  EmitTo output.reset
]

let handlers = IntMap.empty
  |> IntMap.add input.data data_handler
  |> IntMap.add input.reset reset_handler

let vm = Vm.create ~stack_capacity:30 ~max_steps:100 ~mem_size:2

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
	  
	  


