open OUnit2
open Instructions
open Snapshot

let pp_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"


let rec pairs = function
  | a :: b :: rest -> (a, b) :: pairs rest
  | [] -> []
  | [_] -> failwith "observer stream has odd length"


(* ------------------------------------------------------------ *)
(* Test: Chess Clock                                            *)
(* ------------------------------------------------------------ *)

let test_chess_clock _ctx =
  (* Shared VM for all nodes *)
  let vm = Vm.create ~stack_capacity:100 ~max_steps:100 ~mem_size:1 in

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
      LoadMeta OutPortCount; (* push ceil *)
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
  (* Node: observer                                               *)
  (* Keeps [a_count; b_count] and emits pair on every update      *)
  (* ------------------------------------------------------------ *)
  let vm_obs = Vm.create ~stack_capacity:100 ~max_steps:100 ~mem_size:2 in
  let bObs = Builder.Node.create ~state:[5; 5] ~vm:vm_obs in
  
  let handle i = [
      PushA; Store i;          (* update node's state *)
      Load 0; PeekA; EmitTo 0; (* emit A *)
      Load 1; PeekA; EmitTo 0; (* emit B *)
  ] in
  
  let inA_obs =  bObs.add_handler (handle 0) in
  let inB_obs =  bObs.add_handler (handle 1) in
  
  let outObs = bObs.add_out_port () in
  let nodeObs = bObs.finalize () in


  (* ------------------------------------------------------------ *)
  (* Build network                                                *)
  (* ------------------------------------------------------------ *)
  let nb, ( --> ) = Builder.Net.create () in

  let idGen = nb.add_node nodeGen in
  let idSw  = nb.add_node nodeSw in
  let idRouter   = nb.add_node nodeRouter in
  let idA   = nb.add_node nodeA in
  let idB   = nb.add_node nodeB in
  let idObs = nb.add_node nodeObs in


  (* gen → router.tick *)
  (idGen, outGen) --> (idRouter, inTick);

  (* switch → router.pulse *)
  (idSw, outSw) --> (idRouter, inPulse);

  (* router → counters *)
  (idRouter, outA) --> (idA, inA);
  (idRouter, outB) --> (idB, inB);
  
  (* counters  →  observer *)
  (idA, outA_count) --> (idObs, inA_obs);
  (idB, outB_count) --> (idObs, inB_obs);


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
  
  let streamObs =
    Digest.node_out_stream_on_port ~node_id:idObs ~out_port:outObs digest
  in
  
  let obs_pairs = pairs streamObs in
  
  let expected = [
     (4, 5);
	 (3, 5);
	 (3, 4);
	 (3, 3);
	 (2, 3);
	 (1, 3);
	 (0, 3)
  ] in
  
  Printf.printf "Observer:\n";
  Printf.printf "A B\n";
  Printf.printf "===\n%s\n"
    (String.concat "\n"
       (List.map (fun (a,b) -> Printf.sprintf "%d %d" a b) obs_pairs));

  Printf.printf "Counter A: %s\n" (pp_list streamA);
  Printf.printf "Counter B: %s\n" (pp_list streamB);

  (* Expected behavior:
     - First two ticks go to A
     - Switch toggles to B
     - Next two ticks go to B
     - Switch toggles back to A
     - Following ticks goes to A until it zeroes.
  *)
  assert_equal expected obs_pairs

(* ------------------------------------------------------------ *)

let suite =
  "chess clock tests" >::: [
    "test chess clock" >:: test_chess_clock;
  ]

let () = run_test_tt_main suite
