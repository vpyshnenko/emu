(* unlocker.ml - Aggregates auth_ok signals from multiple leaves *)

open Emu

type unlocker_input = {
  auth_ok : int array;  (* One input port per leaf *)
}

type unlocker_output = {
  auth_ok : int;        (* Single output to payload and observer *)
}

type unlocker = {
  node: Node.t;
  id : int;
  input : unlocker_input;
  output : unlocker_output;
}

let make_unlocker ~n () : unlocker =
  let vm = Vm.create ~stack_capacity:30 ~max_steps:100 ~mem_size:0 in
  let b = Builder.Node.create ~state:[] ~vm in
  
  (* Create N input ports, one per leaf *)
  let auth_ok_inputs = Array.init n (fun _ ->
    b.add_handler [
      PushA;           (* Forward the auth value *)
      EmitTo 0;        (* All go to the same output port *)
    ]
  ) in
  
  (* Single output port *)
  let auth_ok_output = b.add_out_port () in
  
  let input: unlocker_input = { auth_ok = auth_ok_inputs } in
  let output: unlocker_output = { auth_ok = auth_ok_output } in
  
  let node = b.finalize () in
  
  {
    id = node.id;
    node;
    input;
    output;
  }