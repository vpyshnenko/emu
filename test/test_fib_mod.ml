open OUnit2
open Instructions

let make_vm ~mem_size () =
  Vm.create ~stack_capacity:100 ~max_steps:100 ~mem_size
  


let pp_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"
  

(* ------------------------------------------------------------ *)
(* Test: Fibonacci network with AddMod                          *)
(* ------------------------------------------------------------ *)

let test_fibonacci_mod_network _ctx =
  let vm = make_vm ~mem_size:2 () in
  let ceil = 21 in

  (* AddMod program *)
  (* Emits:
     - symbolic index 1 if overflow
     - symbolic index 0 otherwise
  *)
 let addmod_prog = [
    Load 1; (* put ceil on the bottom *)
	Load 0; (* put 0 as initial value for counter *)
	PushA; (* push incoming value *)
    AddMod;
	PeekA; (* copy overflow val to regA *)
    EmitIfNonZero 1;   (* overflow symbolic index *)
    Pop;    (* remove overflow val  from stack *)
    PeekA; (* copy sum to reg A *)
    EmitTo 0;          (* default symbolic index *)
    Store 0; (* store sum to mem[0] *)
  ] in
  
  (* forward_prog: takes symbolic index for ch_out *)
  let forward_prog ch_out = [
	  Load 0; (* copy counter val *)
      HaltIfEq (0, 0);
      EmitTo 0;        (* default symbolic index *)
      EmitTo ch_out;   (* symbolic index for ch_out *)
      PushConst (-1);
	  Add;
	  Store 0;
    ] in

  (* ------------------------------------------------------------ *)
  (* Node A                                                       *)
  (* ------------------------------------------------------------ *)
  let bA = Builder.Node.create ~state:[0; ceil] ~vm in
  let inA = bA.add_handler addmod_prog in
  let outA = bA.add_out_port () in          (* actual ID *)
  let outA_overflow = bA.add_out_port () in (* actual ID *)
  let nodeA = bA.finalize () in

  (* ------------------------------------------------------------ *)
  (* Node B                                                       *)
  (* ------------------------------------------------------------ *)
  let bB = Builder.Node.create ~state:[0; ceil] ~vm in
  let inB = bB.add_handler addmod_prog in
  let outB = bB.add_out_port () in
  let outB_overflow = bB.add_out_port () in
  let nodeB = bB.finalize () in

  (* ------------------------------------------------------------ *)
  (* Node C                                                       *)
  (* ------------------------------------------------------------ *)
  let limit = 10 in
  let vm = make_vm ~mem_size:1 () in
  
  let bC = Builder.Node.create ~state:[limit] ~vm in

  (* Node C has 3 outgoing ports: default, ch1_out, ch2_out *)
  let outC = bC.add_out_port () in
  let outC_ch1 = bC.add_out_port () in
  let outC_ch2 = bC.add_out_port () in
  

  (* Handlers use symbolic indices:
     default = 0
     ch1_out = 1
     ch2_out = 2
  *)
  let inC_ch1 = bC.add_handler (forward_prog 1) in
  let inC_ch2 = bC.add_handler (forward_prog 2) in
  let inC_overflow = bC.add_handler [Halt] in

  let nodeC = bC.finalize () in

  (* ------------------------------------------------------------ *)
  (* Build network using Builder.Net + DSL wiring operator        *)
  (* ------------------------------------------------------------ *)
  let nb, ( --> ) = Builder.Net.create () in

  let idA = nb.add_node nodeA in
  let idB = nb.add_node nodeB in
  let idC = nb.add_node nodeC in

  (* Wiring using actual port IDs *)
  (idA, outA) --> (idC, inC_ch1);
  (idC, outC_ch1) --> (idB, inB);
  (idB, outB) --> (idC, inC_ch2);
  (idC, outC_ch2) --> (idA, inA);

  (* Overflow wiring *)
  (idB, outB_overflow) --> (idC, inC_overflow);
  (idA, outA_overflow) --> (idC, inC_overflow);

  let net = nb.finalize () in

  (* ------------------------------------------------------------ *)
  (* Run simulation                                               *)
  (* ------------------------------------------------------------ *)

let init_snap = Runtime.create ~lifespan:30 net in

(* One avalanche triggered by sending payload=1 to node B *)
let schedule = [
  { Runtime.src = idC; out_port = outC_ch1; payload = 1 };
] in

let digest =
  Runtime.run ~schedule init_snap
in

let res_stream =
  Digest.node_out_stream_on_port ~node_id:idC ~out_port:outC digest
in

Printf.printf "Total steps: %d\n" (Digest.total_steps digest.history);
Printf.printf "NodeC emitted values: %s\n" (pp_list res_stream);

assert_equal [1; 1; 2; 3; 5; 8; 13] res_stream
  

(* ------------------------------------------------------------ *)

let suite =
  "runtime tests" >::: [
    "test fibonacci modulo" >:: test_fibonacci_mod_network;
  ]

let () = run_test_tt_main suite
