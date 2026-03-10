open Emu

(* Define separate types for input and output port structures *)
type router_input = {
  setup : int;
  auth : int;
  setup_reset : int;
  auth_reset : int;
}

type router_output = {
  setup : int array;  (* setup[0..n-1] *)
  auth : int array;   (* auth[0..n-1] *)
}

type router = {
  node: Node.t;
  id : int;
  input : router_input;
  output : router_output;
}

let _make_router ~n ~is_root () : router =
  let vm = Vm.create ~stack_capacity:30 ~max_steps:100 ~mem_size:2 in
  let initial_state = if is_root then [1;1] else [0;0] in
  let b = Builder.Node.create ~state:initial_state ~vm in
  
  let setup = b.add_handler [ 
    Load 0; Eq 1; BranchOf [|
      [ PushA; LogStack; Emit; PushConst 0; Store 0 ];
    |];
  ] in
  
  let auth = b.add_handler [
    Load 1; Eq 1; BranchOf [|
      [ PushA; PushConst 2; Add; Emit; PushConst 0; Store 1 ];
    |];
  ] in
  
  let setup_reset = b.add_handler (
    if is_root then [ PushConst 1; Store 0 ] else [ PushConst 0; Store 0 ]
  ) in
  
  let auth_reset = b.add_handler (
    if is_root then [ PushConst 1; Store 1 ] else [ PushConst 0; Store 1 ]
  ) in
  
  (* OUTPUT PORTS - in declaration order *)
  let setup_out = Array.init n (fun _ -> b.add_out_port ()) in
  let auth_out = Array.init n (fun _ -> b.add_out_port ()) in
  
  (* Build the record with all captured port IDs *)
  let input = {
    setup;
    auth;
    setup_reset;
    auth_reset;
  } in
  
  let output = {
    setup = setup_out;
    auth = auth_out;
  } in
  
  let node = b.finalize () in
  
  {
    id = node.id;
    node;
    input;
    output;
  }
let make_root_router ~n = _make_router ~n ~is_root:true () 
let make_router ~n = _make_router ~n ~is_root:false () 