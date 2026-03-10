(* leaf.ml - Leaf node for digital locker *)

open Emu

(* Define input and output port structures *)
type leaf_input = {
  setup : int;    (* Port to receive setup token *)
  auth : int;      (* Port to receive auth token *)
  reset : int;           (* Port to reset the leaf *)
}

type leaf_output = {
  auth_ok : int;         (* Emit when auth succeeds *)
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
  let vm = Vm.create ~stack_capacity:30 ~max_steps:100 ~mem_size:1 in
  let initial_state = [0] in  (* Leaf starts with no token *)
  let b = Builder.Node.create ~state:initial_state ~vm in
  
  (* INPUT PORTS - in declaration order *)
  let setup = b.add_handler [
    PushConst 1;        (* Push token flag *)
    Store 0;            (* Store in state[0] - now has token *)
    PopA;               (* move 1 to regA *)
    EmitTo 2;           (* Emit to port 2 (setup_ok) *)
  ] in
  
  let auth = b.add_handler [
    PushConst 1;        
    PopA;               (* Move 1 to reg A *)
    Load 0;             (* Check if we have token (state[0]) *)
    Eq 1;               (* Compare with 1 *)
    BranchOf [|
      [ EmitTo 0 ];     (* Token present → auth success (port 0) *)
      [ EmitTo 1 ];     (* No token → auth fail (port 1) *)
    |];
  ] in
  
  let reset = b.add_handler [
    PushConst 0;        (* Push 0 to clear token *)
    Store 0;            (* state[0] = 0 - clear token *)
  ] in
  
  (* OUTPUT PORTS - in declaration order *)
  let auth_ok = b.add_out_port () in      (* port 0 *)
  let auth_fail = b.add_out_port () in    (* port 1 *)
  let setup_ok = b.add_out_port () in     (* port 2 *)
  
  (* Build the record with all captured port IDs *)
  let input = {
    setup;
    auth;
    reset;
  } in
  
  let output = {
    auth_ok;
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
