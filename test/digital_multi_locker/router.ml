(* router.ml *)

open Emu

(* Define separate types for input and output port structures *)
type router_input = {
  setup_data: int;
  auth_data: int;
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

let make_router ~n : router =
  let vm = Vm.create ~stack_capacity:30 ~max_steps:100 ~mem_size:2 in
  let initial_state = [0;0] in
  let b = Builder.Node.create ~state:initial_state ~vm in
  
  let setup_data = b.add_handler [
    Load 0; Eq 0; BranchOf [|
      [ 
	    PushConst 1; Store 0; 
		PushA; Store 1;
	  ];
      [ Load 1; Emit; ];
    |];
  ] in
  
  let auth_data = b.add_handler [
    Load 0; Eq 0; BranchOf [|
      [ 
	    PushA;
		LoadMeta OutPortCount; PushConst 1; Shr;  (* 2N >> 1 = N *)
		Add; Store 1;
        PushConst 1; Store 0;		
	  ];
      [ PushConst 1; Add; Store 0; Load 1; Emit; ];
    |];
	(* Load 0; Eq 2; BranchOf [| *)
	  (* [ PushConst 1; PopA; Load 1; LogMem; Emit; ] *)
	(* |]; *)
  ] in
  
  let setup_reset = b.add_handler [
    PushConst 0;
	Store 0;
	Store 1;
  ] in
  
  let auth_reset = b.add_handler [
    PushConst 0;
	Store 0;
	Store 1;
  ] in
  
  (* OUTPUT PORTS - in declaration order *)
  let setup_out = Array.init n (fun _ -> b.add_out_port ()) in
  let auth_out = Array.init n (fun _ -> b.add_out_port ()) in
  
  (* Build the record with all captured port IDs *)
  let input = {
    setup_data;
    auth_data;
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
