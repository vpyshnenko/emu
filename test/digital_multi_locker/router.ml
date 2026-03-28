(* router.ml *)

open Emu
open Emu.Instructions

module IntMap = Map.Make(Int)

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

let make_ports ~n =
  let input = { setup_data = 0; auth_data = 1 } in
  let output = { 
    setup = Array.init n (fun i -> i);
    auth = Array.init n (fun i -> i + n);
  } in
  let out_ports = Array.to_list output.setup @ Array.to_list output.auth in
  (input, output, out_ports)

let make_setup_handler ~count =
  [
    Load 0; Eq (-1); BranchOf [|
      [ PushA; PushConst (-1); Add; Store 0; Halt ];
    |];
    Load 1; Eq (-1); BranchOf [|
      [ 
        PushA; Store 1;
        Load 0; Gt 1; BranchOf [|
          [ PopA; Load 1; Emit ];
        |]		 
      ];
      [ Load 1; Emit; 
        Load 0; PushConst (-1); Add; Store 0;
      ]
    |];
    Load 0; Eq 0; BranchOf [|
      [ 
        PushConst count; Store 0;
        PushConst (-1); Store 1;
      ]
    |]
  ] 
  
let make_auth_handler ~count =
  [
    Load 0; Eq (-1); BranchOf [|
      [ PushA; PushConst (-1); Add; Store 0; Halt ];
    |];
    Load 1; Eq (-1); BranchOf [|
      [ 
        LoadMeta OutPortCount; PushConst 1; Shr; (* 2N >> 1 = N *)
        PushA; Add; Store 1;
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
  ]

let setup_handler = make_setup_handler ~count:(-1)
let auth_handler = make_auth_handler ~count:(-1)

let vm = Vm.create ~stack_capacity:30 ~max_steps:100 ~mem_size:2
let initial_state = [-1;-1]


let make_router_gen ~n =
  let (input, output, out_ports) = make_ports ~n in
  let handlers = IntMap.empty
    |> IntMap.add input.setup_data setup_handler
    |> IntMap.add input.auth_data auth_handler
  in
  fun ~id  ->
    let node = Node.create 
        ~id 
        ~state:initial_state 
        ~vm 
        ~handlers
        ~out_ports 
        ()
      in
      { id; node; input; output }
	  
	  
let make_root_router ~id ~n ~l =
  let (input, output, out_ports) = make_ports ~n in
  let handlers = IntMap.empty
    |> IntMap.add input.setup_data (make_setup_handler ~count:l)
    |> IntMap.add input.auth_data (make_auth_handler ~count:l)
  in
  let node = Node.create 
      ~id 
      ~state:[l; -1]
      ~vm 
      ~handlers
      ~out_ports 
      ()
   in
   { id; node; input; output }

