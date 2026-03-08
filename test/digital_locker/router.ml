
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

let make_router ~n () : router =
  let vm = Vm.create ~stack_capacity:30 ~max_steps:100 ~mem_size:2 in
  
  (* Create the node builder with initial state [setup_token; auth_token] *)
  let b = Builder.Node.create ~state:[1;1] ~vm in
  
  (* Add input handlers and capture their port IDs *)
  let in_setup_digit = 
    b.add_handler [
      Load 0;        (* Stack: [token] - push setup_token onto stack *)
      Eq 1;          (* Stack: [0] if token==1, [1] if token!=1 *)
      BranchOf [|
        [  (* Token present case - branch index 0 *)
          PushA;     (* Stack: [digit] - push digit from register A *)
          Emit;      (* Send digit to port = digit value (routes to leaf[digit]) *)
          PushConst 0;  (* Stack: [0] - prepare to clear token *)
          Store 0;      (* state[0] = 0 - clear setup_token *)
        ];
        (* Token absent case - empty branch, just continue *)
      |];
    ]
  in
  
  let in_auth_digit =
    b.add_handler [
      Load 1;        (* Stack: [token] - push auth_token from state[1] *)
      Eq 1;          (* Stack: [0] if token==1, [1] if token!=1 *)
      BranchOf [|
        [  (* Token present case *)
          PushA;     (* Stack: [digit] - push auth digit from regA *)
          PushConst 2;  (* Stack: [digit, 2] - push shift constant *)
          Add;       (* Stack: [digit+2] - shift to auth port range *)
          Emit;      (* Send to port = digit+2 (routes to leaf[digit] auth port) *)
          PushConst 0;  (* Stack: [0] - prepare to clear token *)
          Store 1;      (* state[1] = 0 - clear auth_token *)
        ];
      |];
    ]
  in
  
  let in_reset_setup =
    b.add_handler [
      PushConst 1;   (* Push 1 to set token *)
      Store 0;       (* state[0] = 1 - set setup_token *)
    ]
  in
  
  let in_reset_auth =
    b.add_handler [
      PushConst 1;   (* Push 1 to set token *)
      Store 1;       (* state[1] = 1 - set auth_token *)
    ]
  in
  
  (* Create output ports and capture their IDs *)
  let out_setup = Array.init n (fun _ -> b.add_out_port ()) in
  let out_auth = Array.init n (fun _ -> b.add_out_port ()) in
  
  (* Finalize the node - this creates the actual Node.t with a unique ID *)
  let node = b.finalize () in
  
  {
    id = node.Node.id;  (* Get the assigned ID from the finalized node *)
	node;
    input = {
      setup_digit = in_setup_digit;
      auth_digit = in_auth_digit;
      reset_setup = in_reset_setup;
      reset_auth = in_reset_auth;
    };
    output = {
      setup = out_setup;
      auth = out_auth;
    }
  }