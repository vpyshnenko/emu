
(* Define separate types for input and output port structures *)
type router_input = {
  setup_digit : int;
  auth_digit : int;
  reset_setup : int;
  reset_auth : int;
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
  (* Root starts with tokens=1, children start with tokens=0 *)
  let initial_state = if is_root then [1;1] else [0;0] in
  let b = Builder.Node.create ~state:initial_state ~vm in
  
  let input = {
    setup_digit = b.add_handler [ 
      Load 0; Eq 1; BranchOf [|
        [ PushA; Emit; PushConst 0; Store 0 ];
      |];
    ];
    auth_digit = b.add_handler [
      Load 1; Eq 1; BranchOf [|
        [ PushA; PushConst 2; Add; Emit; PushConst 0; Store 1 ];
      |];
    ];
    (* Reset behavior depends on router type *)
    reset_setup = b.add_handler (
      if is_root then
        [ PushConst 1; Store 0 ]  (* Root: re-arm setup_token *)
      else
        [ PushConst 0; Store 0 ]  (* Child: keep disabled *)
    );
    reset_auth = b.add_handler (
      if is_root then
        [ PushConst 1; Store 1 ]  (* Root: re-arm auth_token *)
      else
        [ PushConst 0; Store 1 ]  (* Child: keep disabled *)
    );
  } in
  
  let output = {
    setup = Array.init n (fun _ -> b.add_out_port ());
    auth = Array.init n (fun _ -> b.add_out_port ());
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