(* router.ml *)

open Emu

(* Define separate types for input and output port structures *)
type router_input = {
  setup_data: int;
  auth_data: int;
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

let make_router ~n ~l ~is_root (): router =
  let vm = Vm.create ~stack_capacity:30 ~max_steps:100 ~mem_size:2 in
  let count = if is_root then l else (-1) in
  
  let initial_state = if is_root then [count; -1] else [-1;-1] in
  let b = Builder.Node.create ~state:initial_state ~vm in
  
  
  
  let setup_data = b.add_handler [
    Load 0; Eq (-1); BranchOf [|
	    [ PushA; PushConst (-1); Add; Store 0; Halt];
	|];
	Load 1; Eq (-1); BranchOf [|
      [ 
		PushA; Store 1;
        Load 0; Gt 1; BranchOf [|
		 [ PopA; Load 1; Emit;]
        |]		 
	  ];
      [ Load 1; Emit; 
	  	Load 0; PushConst (-1); Add; Store 0;
		Eq 0; BranchOf [|
		  [ 
		    PushConst count; Store 0;
		    PushConst (-1); Store 1;
		  ]
		|]
	  ]
    |];
  ] in
  

  
  let auth_data = b.add_handler [
    Load 0; Eq (-1); BranchOf [|
	    [ PushA; PushConst (-1); Add; Store 0; Halt];
	|];
    Load 1; Eq (-1); BranchOf [|
	  [ 
		LoadMeta OutPortCount; PushConst 1; Shr; (* 2N >> 1 = N *)
	    PushA; Add; Store 1;
		(* Load 0; Gt 1; BranchOf [| *)
		 (* [ PopA; Load 1; Emit;] *)
        (* |]	 *)
        Load 0; PopA; Load 1; Emit;
	  ];
      [ 
	    Load 1; Emit;
	    Load 0; PushConst (-1); Add; Store 0;
	  ]
	|];
	Load 0; Eq 1; BranchOf [|
	  [ 
	    PushConst count; Store 0;
	    PushConst (-1); Store 1;
	  ]
	|]
		

  ] in 
  
  (* OUTPUT PORTS - in declaration order *)
  let setup_out = Array.init n (fun _ -> b.add_out_port ()) in
  let auth_out = Array.init n (fun _ -> b.add_out_port ()) in
  
  (* Build the record with all captured port IDs *)
  let input = {
    setup_data;
    auth_data;
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
