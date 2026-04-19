open OUnit2
open Emu
open Emu.Instructions

let make_vm ~mem_size () =
  Vm.create ~stack_capacity:100 ~max_steps:100 ~mem_size
  


let pp_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"
  

(* ------------------------------------------------------------ *)
(* Test: Loop Instruction                         *)
(* ------------------------------------------------------------ *)

let test_loop _ctx =

  let nodeExt = Emu.Node.add_out_port ~actual_id:0 Emu.Node.empty in



  (* ------------------------------------------------------------ *)
  (* Node A                                                       *)
  (* ------------------------------------------------------------ *)
  let vm = make_vm ~mem_size:2 () in

  let bA = Builder.Node.create ~state:[5;0] ~vm () in
  
  let countdownOut = bA.add_out_port () in
  let countdownIn = bA.add_handler [
    Load 0; Eq 0;
    Loop [
	  PeekA;
      EmitTo countdownOut;
      PushConst (-1); Add;
      Eq 0         (* leave loop if 0 is on stack top *)
    ]
  ] in
  
  let sumOut = bA.add_out_port () in
  let sumIn = bA.add_handler [
    PushConst 0;
	PushConst 1;  (* Non-zero to force loop entry *)
    Loop [
	  Dup; Load 1; Add; Store 1; 
	  PopA; EmitTo sumOut;
      PushConst 1; Add;
	  
      Gt 5         (* leave loop if 0 is on stack top *)
    ]
  ] in
  
  
  let nodeA = bA.finalize () in

  let nb, ( --> ) = Builder.Net.create () in

  nb.add_node nodeExt;
  nb.add_node nodeA;


  (* Wiring using actual port IDs *)
  (nodeExt.id, 0) --> (nodeA.id, sumIn);
  (nodeExt.id, 0) --> (nodeA.id, countdownIn);

  let net = nb.finalize () in

  (* ------------------------------------------------------------ *)
  (* Run simulation                                               *)
  (* ------------------------------------------------------------ *)

let init_snap = Runtime.create net in

(* One avalanche triggered by sending payload=1 to node B *)
let schedule = [
  { Runtime.src = nodeExt.id; out_port = 0; payload = 1 };
] in

let digest =
  Runtime.run ~schedule init_snap
in

Printf.printf "\n ====Loop test======\n"; 

let countdown_stream =
  Digest.node_out_stream_on_port ~node_id:nodeA.id ~out_port:countdownOut digest
in

Printf.printf "countdown out: %s\n" (pp_list countdown_stream);

assert_equal [5; 4; 3; 2; 1] countdown_stream;

let sum_stream =
  Digest.node_out_stream_on_port ~node_id:nodeA.id ~out_port:sumOut digest
in

Printf.printf "sum out: %s\n" (pp_list sum_stream);
assert_equal [0; 1; 3; 6; 10; 15] sum_stream

(* ------------------------------------------------------------ *)

let suite =
  "runtime tests" >::: [
    "loop tests" >:: test_loop;
  ]

let () = run_test_tt_main suite
