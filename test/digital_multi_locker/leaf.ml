(* leaf.ml - Leaf node for digital locker *)

open Emu

(* Define input and output port structures *)
type leaf_input = {
  setup : int;    (* Port to receive setup token *)
  auth : int;      (* Port to receive auth token *)
  reset : int;           (* Port to reset the leaf *)
}

type leaf_output = {
  value : int;         (* Emit when auth succeeds *)
  auth_fail : int;       (* Emit when auth fails *)
  setup_ok : int;        (* Emit when setup completes *)
}

type leaf = {
  node: Node.t;
  id : int;
  input : leaf_input;
  output : leaf_output;
}

let make_leaf () : leaf =
  let vm = Vm.create ~stack_capacity:30 ~max_steps:100 ~mem_size:2 in
  let initial_state = [0;0] in 
  let b = Builder.Node.create ~state:initial_state ~vm in
  
  (* INPUT PORTS - in declaration order *)
  let setup = b.add_handler [
    PushConst 1;        (* Push not_empty flag *)
    Store 0;            (* Store in state[0] - now has value *)
	PushA;
	Store 1;            (* Store secret value in state[1] *)
    PushConst 1;               
	PopA;               (* move 1 to regA *)
    EmitTo 2;           (* Emit to port 2 (setup_ok) *)
  ] in
  
  let auth = b.add_handler [
    Load 0;             (* Check if we have token (state[0]) *)
    Eq 1;               (* Compare with 1 *)
    BranchOf [|
      [ Load 1; PopA; EmitTo 0; ];     (* auth success → emit value to (port 0) *)
      [ PushConst 1; PopA; EmitTo 1 ];     (* auth fail → emit 1 to (port 1) *)
    |];
  ] in
  
  let reset = b.add_handler [
    PushConst 0;        
    Store 0;            (* state[0;0] *)
	Store 1;
  ] in
  
  (* OUTPUT PORTS - in declaration order *)
  let value = b.add_out_port () in      (* port 0 *)
  let auth_fail = b.add_out_port () in    (* port 1 *)
  let setup_ok = b.add_out_port () in     (* port 2 *)
  
  (* Build the record with all captured port IDs *)
  let input = {
    setup;
    auth;
    reset;
  } in
  
  let output = {
    value;
    auth_fail;
    setup_ok;
  } in
  
  let node = b.finalize () in
  
  {
    id = node.id;
    node;
    input;
    output;
  }
