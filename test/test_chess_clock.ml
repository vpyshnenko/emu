open OUnit2
open Instructions
open Snapshot

let make_vm () =
  Vm.create ~stack_capacity:100 ~max_steps:100 ~mem_size:1

let pp_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"

(* ------------------------------------------------------------ *)
(* Test: Chess Clock                                            *)
(* ------------------------------------------------------------ *)

let test_chess_clock _ctx =
  (* Shared VM for all nodes *)
  let vm = make_vm () in

  (* ------------------------------------------------------------ *)
  (* Node: gen (tick source)                                     *)
  (* ------------------------------------------------------------ *)
  let bGen = Builder.Node.create ~state:[] ~vm in
  let outGen = bGen.add_out_port () in
  let nodeGen = bGen.finalize () in

  (* ------------------------------------------------------------ *)
  (* Node: switch (pulse source)                                 *)
  (* ------------------------------------------------------------ *)
  let bSw = Builder.Node.create ~state:[] ~vm in
  let outSw = bSw.add_out_port () in
  let nodeSw = bSw.finalize () in

  (* ------------------------------------------------------------ *)
  (* Node: router                                                 *)
  (* State:                                                       *)
  (* 0: curent active out port index                              *)
  (* 1: out ports count (ceil)                                    *)
  (* ------------------------------------------------------------ *)
  let bRouter = Builder.Node.create ~state:[0] ~vm in

  (* Incoming ports: 1 = tick, 2 = switch pulse *)
  let inTick =
    bRouter.add_handler [
      Load 0;          (* load active port *)
      Emit;        
    ]
  in

  let inPulse =
    bRouter.add_handler [
      LoadMeta 1; (* push ceil *)
	  Load 0; (* push current active out port index *)
      PushConst 1;
      AddMod;
	  Pop; (* pop overflow *)
      Store 0;
    ]
  in

  let outA = bRouter.add_out_port () in
  let outB = bRouter.add_out_port () in
  let nodeRouter = bRouter.finalize () in

  (* ------------------------------------------------------------ *)
  (* Node: counterA                                               *)
  (* ------------------------------------------------------------ *)
  let bA = Builder.Node.create ~state:[5] ~vm in

  let inA =
    bA.add_handler [
      Load 0;
      PushConst (-1);
      Add;
      Store 0;
      PeekA;
      EmitTo 0;
    ]
  in

  let outA_count = bA.add_out_port () in
  let nodeA = bA.finalize () in

  (* ------------------------------------------------------------ *)
  (* Node: counterB                                               *)
  (* ------------------------------------------------------------ *)
  let bB = Builder.Node.create ~state:[5] ~vm in

  let inB =
    bB.add_handler [
      Load 0;
      PushConst (-1);
      Add;
      Store 0;
      PeekA;
      EmitTo 0;
    ]
  in

  let outB_count = bB.add_out_port () in
  let nodeB = bB.finalize () in

  (* ------------------------------------------------------------ *)
  (* Build network                                                *)
  (* ------------------------------------------------------------ *)
  let nb, ( --> ) = Builder.Net.create () in

  let idGen = nb.add_node nodeGen in
  let idSw  = nb.add_node nodeSw in
  let idRouter   = nb.add_node nodeRouter in
  let idA   = nb.add_node nodeA in
  let idB   = nb.add_node nodeB in

  (* gen → router.tick *)
  (idGen, outGen) --> (idRouter, inTick);

  (* switch → router.pulse *)
  (idSw, outSw) --> (idRouter, inPulse);

  (* router → counters *)
  (idRouter, outA) --> (idA, inA);
  (idRouter, outB) --> (idB, inB);

  let net = nb.finalize () in

  (* ------------------------------------------------------------ *)
  (* Schedule                                                     *)
  (* ------------------------------------------------------------ *)
  let schedule = [
    { Runtime.src = idGen; out_port = outGen; payload = 1 };
    { Runtime.src = idGen; out_port = outGen; payload = 1 };
    { Runtime.src = idSw;  out_port = outSw;  payload = 1 }; (* switch to B *)
    { Runtime.src = idGen; out_port = outGen; payload = 1 };
    { Runtime.src = idGen; out_port = outGen; payload = 1 };
    { Runtime.src = idSw;  out_port = outSw;  payload = 1 }; (* switch to A *)
    { Runtime.src = idGen; out_port = outGen; payload = 1 };
    { Runtime.src = idGen; out_port = outGen; payload = 1 };
    { Runtime.src = idGen; out_port = outGen; payload = 1 };
    { Runtime.src = idGen; out_port = outGen; payload = 1 };
  ] in

  (* ------------------------------------------------------------ *)
  (* Run simulation                                               *)
  (* ------------------------------------------------------------ *)
  let init_snap = Runtime.create ~lifespan:100 net in
  
  let stop_when snap =
    let a = Net.get_node snap.net idA in
    let b = Net.get_node snap.net idB in
    let a_count = List.hd a.state in
    let b_count = List.hd b.state in
    a_count <= 0 || b_count <= 0
  in
  
  let digest =
    Runtime.run
      ~stop_when
      ~schedule
      init_snap
  in

  let streamA =
    Digest.node_out_stream_on_port ~node_id:idA ~out_port:outA_count digest
  in

  let streamB =
    Digest.node_out_stream_on_port ~node_id:idB ~out_port:outB_count digest
  in

  Printf.printf "Counter A: %s\n" (pp_list streamA);
  Printf.printf "Counter B: %s\n" (pp_list streamB);

  (* Expected behavior:
     - First two ticks go to A
     - Switch toggles to B
     - Next two ticks go to B
     - Switch toggles back to A
     - Last tick goes to A
  *)

  assert_equal [4; 3; 2; 1; 0] streamA;
  assert_equal [4; 3] streamB

(* ------------------------------------------------------------ *)

let suite =
  "chess clock tests" >::: [
    "test chess clock" >:: test_chess_clock;
  ]

let () = run_test_tt_main suite
