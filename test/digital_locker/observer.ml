(* observer.ml - Observer node for digital locker tests *)

open Emu

(* Define input and output port structures *)
type observer_input = {
  setup_ok : int;     (* Port to receive setup success notifications *)
  auth_fail : int;    (* Port to receive auth failure notifications *)
  auth_ok : int;    (* Port to receive auth success notifications *)
}

type observer_output = {
  setup_ok : int;     (* Output port for setup success (to external) *)
  auth_fail : int;    (* Output port for auth failure (to external) *)
  auth_ok : int;    (* Output port for auth success (to external) *)
}

type observer = {
  node: Node.t;
  id : int;
  input : observer_input;
  output : observer_output;
}

let make_observer () : observer =
  let vm = Vm.create ~stack_capacity:30 ~max_steps:100 ~mem_size:0 in
  let initial_state = [] in  (* Observer is stateless *)
  let b = Builder.Node.create ~state:initial_state ~vm in
  
  (* INPUT PORTS - in declaration order *)
  let setup_ok = b.add_handler [
    PushConst 1;        (* Push 1 to emit *)
    PopA;               (* Move to regA (value doesn't matter) *)
    EmitTo 0;           (* Emit to port 0 (setup_ok output) *)
  ] in
  
  let auth_fail = b.add_handler [
    PushConst 1;        (* Push 1 to emit *)
    PopA;               (* Move to regA *)
    EmitTo 1;           (* Emit to port 1 (auth_fail output) *)
  ] in
  
  let auth_ok = b.add_handler [
    PushConst 1;        (* Push 1 to emit *)
    PopA;               (* Move to regA *)
    EmitTo 2;           (* Emit to port 1 (auth_ok output) *)
  ] in
  
  (* OUTPUT PORTS - in declaration order *)
  let setup_ok_out = b.add_out_port () in   (* port 0 *)
  let auth_fail_out = b.add_out_port () in  (* port 1 *)
  let auth_ok_out = b.add_out_port () in  (* port 2 *)
  
  (* Build the record with all captured port IDs *)
  let input: observer_input = {
    setup_ok;
    auth_fail;
    auth_ok;
  } in
  
  let output: observer_output = {
    setup_ok = setup_ok_out;
    auth_fail = auth_fail_out;
    auth_ok = auth_ok_out;
  } in
  
  let node = b.finalize () in
  
  {
    id = node.id;
    node;
    input;
    output;
  }