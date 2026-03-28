(* leaf.ml - Leaf node for digital locker *)

open Emu
open Emu.Instructions

module IntMap = Map.Make(Int)

(* Define input and output port structures *)
type leaf_input = {
  setup : int;    (* Port to receive setup token *)
  auth : int;     (* Port to receive auth token *)
  reset : int;    (* Port to reset the leaf *)
}

type leaf_output = {
  value : int;           (* Emit when auth succeeds *)
  auth_fail : int;       (* Emit when auth fails *)
  setup_ok : int;        (* Emit when password setup completes *)
}

type leaf = {
  node: Node.t;
  id : int;
  input : leaf_input;
  output : leaf_output;
}

let vm = Vm.create ~stack_capacity:30 ~max_steps:100 ~mem_size:2
let initial_state = [0;0]

let input = { setup = 0; auth = 1; reset = 2 }
let output = { value = 0; auth_fail = 1; setup_ok = 2 }

let setup_handler = [
    PushConst 1;        (* Push not_empty flag *)
    Store 0;            (* Store in state[0] - now has value *)
	PushA;
	Store 1;            (* Store secret value in state[1] *)
    PushConst 1;               
	PopA;               (* move 1 to regA *)
    EmitTo 2;           (* Emit to port 2 (setup_ok) *)
  ]
  
let auth_handler = [
    Load 0;             (* Check if we have token (state[0]) *)
    Eq 1;               (* Compare with 1 *)
    BranchOf [|
      [ Load 1; PopA; EmitTo 0; ];     (* auth success → emit value to (port 0) *)
      [ PushConst 1; PopA; EmitTo 1 ];     (* auth fail → emit 1 to (port 1) *)
    |];
  ]
  
let reset_handler = [
    PushConst 0;        
    Store 0;            (* state[0;0] *)
	Store 1;
  ]
  

let handlers = IntMap.empty
    |> IntMap.add input.setup setup_handler
    |> IntMap.add input.auth auth_handler
    |> IntMap.add input.reset reset_handler



let out_ports = [output.value; output.auth_fail; output.setup_ok]

let make_leaf ~id : leaf =
  let node = Node.create 
    ~id 
    ~state:initial_state 
    ~vm 
    ~handlers
    ~out_ports 
    ()
  in
  {
    id;
    node;
    input;
    output;
  }
