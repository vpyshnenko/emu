open OUnit2
open Instructions

let addmod_prog = [
  AddMod;
  Pop;
  Emit;
]

let make_vm () =
  Vm.create ~stack_capacity:10 ~max_steps:10
  
let pp_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"

module IntMap = Map.Make(Int)

(* ------------------------------------------------------------ *)
(* Test 1: Loop detection                                       *)
(* ------------------------------------------------------------ *)

let test_runtime_loop_detection _ctx =
  let vm = make_vm () in

  let nodeA =
    Node.create ~state:[4; 10] ~vm ()
    |> Node.add_handler "addmod" addmod_prog
  in

  let nodeB =
    Node.create ~state:[8; 10] ~vm ()
    |> Node.add_handler "addmod" addmod_prog
  in

  let net =
    Net.create ()
    |> Net.add_node 1 nodeA
    |> Net.add_node 2 nodeB
    |> Net.connect ~src:1 ~dst:2 ~event_name:"addmod"
    |> Net.connect ~src:2 ~dst:1 ~event_name:"addmod"
  in
  


  let expected_msg =
    "runtime: lifetime exceeded (immortal activity detected)"
  in

  assert_raises
    (Failure expected_msg)
    (fun () -> 
		Runtime.create ~lifespan:10 net
		|> Runtime.run ~bang:{ dst = 2; event_name = "addmod"; payload = 3 }
		|> ignore)

(* ------------------------------------------------------------ *)
(* Test 2: Single-hop event delivery                            *)
(* ------------------------------------------------------------ *)

let test_single_hop _ctx =
  let vm = make_vm () in

  let nodeA =
    Node.create ~state:[10] ~vm ()
    |> Node.add_handler "inc" [PushConst 1; Add; Emit]
  in

  let nodeB =
    Node.create ~state:[0] ~vm ()
    |> Node.add_handler "store" [Emit]
  in

  let net =
    Net.create ()
    |> Net.add_node 1 nodeA
    |> Net.add_node 2 nodeB
    |> Net.connect ~src:1 ~dst:2 ~event_name:"store"
  in

  let snap =
    Runtime.create ~lifespan:10 net
  in

  let digest = Runtime.run ~bang:{ dst = 2; event_name = "store"; payload = 5 } snap in
  let final = Digest.final_state digest in

  let nodeA' = IntMap.find 1 final.net.nodes in
  assert_equal [10] nodeA'.state;

  let nodeB' = IntMap.find 2 final.net.nodes in
  assert_equal [5; 0] nodeB'.state

(* ------------------------------------------------------------ *)
(* Test 3: Multi-hop chain A → B → C                            *)
(* ------------------------------------------------------------ *)

let test_multi_hop_chain _ctx =
  let vm = make_vm () in

  let nodeA =
    Node.create ~state:[100] ~vm ()
    |> Node.add_handler "step" [PushConst 2; Add; Emit]
  in

  let nodeB =
    Node.create ~state:[200] ~vm ()
    |> Node.add_handler "step" [PushConst 3; Add; Emit]
  in

  let nodeC =
    Node.create ~state:[0] ~vm ()
    |> Node.add_handler "store" [Emit]
  in

  let net =
    Net.create ()
    |> Net.add_node 1 nodeA
    |> Net.add_node 2 nodeB
    |> Net.add_node 3 nodeC
    |> Net.connect ~src:1 ~dst:2 ~event_name:"step"
    |> Net.connect ~src:2 ~dst:3 ~event_name:"store"
  in

  let snap =
    Runtime.create ~lifespan:20 net
  in

  let digest = Runtime.run ~bang:{ dst = 2; event_name = "step"; payload = 5 } snap in
  let final = Digest.final_state digest in

  let nodeA' = IntMap.find 1 final.net.nodes in
  assert_equal [100] nodeA'.state;

  let nodeB' = IntMap.find 2 final.net.nodes in
  assert_equal [8; 200] nodeB'.state;

  let nodeC' = IntMap.find 3 final.net.nodes in
  assert_equal [8; 0] nodeC'.state

(* ------------------------------------------------------------ *)
(* Test 5: Fibonacci network                                    *)
(* ------------------------------------------------------------ *)

let test_fibonacci_network _ctx =
  let vm = make_vm () in

  let nodeA =
    Node.create ~state:[0] ~vm ()
    |> Node.add_handler "tick" [Add; Emit]
  in

  let nodeB =
    Node.create ~state:[0] ~vm ()
    |> Node.add_handler "tick" [Add; Emit]
  in

  let nodeC =
    Node.create ~vm ()
    |> Node.add_handler "tick" [Emit]
  in

  let limit = 3 in

  let nodeD =
    Node.create ~state:[limit] ~vm ()
    |> Node.add_handler "tick" [
         HaltIfEq (1, 0);
         Emit;
         Pop;
         PushConst (-1);
         Add;
       ]
  in

  let net =
    Net.create ()
    |> Net.add_node 1 nodeA
    |> Net.add_node 2 nodeB
    |> Net.add_node 3 nodeC
    |> Net.add_node 4 nodeD
    |> Net.connect ~src:1 ~dst:4 ~event_name:"tick"
    |> Net.connect ~src:4 ~dst:2 ~event_name:"tick"
    |> Net.connect ~src:2 ~dst:1 ~event_name:"tick"
    |> Net.connect ~src:1 ~dst:3 ~event_name:"tick"
    |> Net.connect ~src:2 ~dst:3 ~event_name:"tick"
  in

  let init_snap =
    Runtime.create ~lifespan:100 net
  in

  let digest = Runtime.run ~bang:{ dst = 2; event_name = "tick"; payload = 1 }init_snap in

  (* TODO Fix Digest.node_out_stream since nodeC_out_stream still is empty *)
  let nodeA_out_stream = Digest.node_out_stream ~node_id: 1 digest in
  let nodeB_out_stream = Digest.node_out_stream ~node_id: 2 digest in
  let nodeC_out_stream = Digest.node_out_stream ~node_id: 3 digest in
  let nodeD_out_stream = Digest.node_out_stream ~node_id: 4 digest in
  
  let nodeA_sent_values = Digest.node_sent_values ~node_id: 1 digest in
  let nodeB_sent_values = Digest.node_sent_values ~node_id: 2 digest in
  let nodeC_sent_values = Digest.node_sent_values ~node_id: 3 digest in
  let nodeD_sent_values = Digest.node_sent_values ~node_id: 4 digest in
  
  
  let nodeA_in_stream = Digest.node_in_stream ~node_id: 1 ~event_name: "tick" digest in
  let nodeB_in_stream = Digest.node_in_stream ~node_id: 2 ~event_name: "tick" digest in
  let nodeC_in_stream = Digest.node_in_stream ~node_id: 3 ~event_name: "tick" digest in
  let nodeD_in_stream = Digest.node_in_stream ~node_id: 4 ~event_name: "tick" digest in
  
  
  let edge_AD_stream = Digest.node_edge_stream ~src: 1 ~dst: 4 digest in
  let edge_DB_stream = Digest.node_edge_stream ~src: 4 ~dst: 2 digest in
  let edge_BA_stream = Digest.node_edge_stream ~src: 2 ~dst: 1 digest in
  let edge_AC_stream = Digest.node_edge_stream ~src: 1 ~dst: 3 digest in
  let edge_BC_stream = Digest.node_edge_stream ~src: 2 ~dst: 3 digest in
  
  let nodeC_state = Digest.final_node_state ~node_id: 3 digest in

  let fib_seq = [1; 1; 2; 3; 5; 8; 13; 21] in
  
  assert_equal (List.rev fib_seq) nodeC_state;
  
  assert_equal [1; 3; 8] nodeD_out_stream;
  assert_equal [1; 3; 8] nodeD_sent_values;
  assert_equal [1; 1; 3; 8] nodeB_in_stream;
  assert_equal [1; 3; 8] edge_DB_stream;
  assert_equal [1; 2; 5; 13] nodeB_out_stream;
  assert_equal [1; 1; 2; 2; 5; 5; 13; 13] nodeB_sent_values;
  assert_equal [1; 2; 5; 13] nodeA_in_stream;
  assert_equal [1; 2; 5; 13] edge_BA_stream;
  assert_equal [1; 3; 8; 21] nodeA_out_stream;
  assert_equal [1; 1; 3; 3; 8; 8; 21; 21] nodeA_sent_values;
  assert_equal [1; 3; 8; 21] nodeD_in_stream;
  assert_equal [1; 3; 8; 21] edge_AD_stream;
  assert_equal [1; 3; 8; 21] edge_AC_stream;
  assert_equal [1; 2; 5; 13] edge_BC_stream;
  assert_equal fib_seq nodeC_in_stream;
  assert_equal fib_seq	nodeC_out_stream;
  assert_equal [] nodeC_sent_values;
  
  Printf.printf "NodeC emitted values: %s\n" (pp_list nodeC_out_stream)	
  
  
  
  

(* ------------------------------------------------------------ *)
(* Test 6: Event deliver order                                   *)
(* ------------------------------------------------------------ *)

let test_event_delivery_order _ctx =
  let vm = make_vm () in

  let nodeA =
    Node.create ~vm () (* empty trigger node *)
  in

  let nodeB =
    Node.create ~state:[] ~vm ()
    |> Node.add_handler "bang" [
         PushConst 1; Emit;
         PushConst 2; Emit;
         PushConst 3; Emit
       ]
  in
  
  let nodeC =
    Node.create ~state:[] ~vm ()
    |> Node.add_handler "in" []
  in

  let net =
    Net.create ()
    |> Net.add_node 1 nodeA
    |> Net.add_node 2 nodeB
    |> Net.add_node 3 nodeC
    |> Net.connect ~src:1 ~dst:2 ~event_name:"bang"
    |> Net.connect ~src:2 ~dst:3 ~event_name:"in"
  in

  let snap =
    Runtime.create ~lifespan:10 net
  in

  let digest = Runtime.run ~bang:{ dst = 2; event_name = "bang"; payload = 1 } snap in
  let final = Digest.final_state digest in

  let nodeC' = IntMap.find 3 final.net.nodes in
  assert_equal [3; 2; 1] nodeC'.state

(* ------------------------------------------------------------ *)

let suite =
  "runtime tests" >::: [
    "loop detection" >:: test_runtime_loop_detection;
    "single hop" >:: test_single_hop;
    "multi hop chain" >:: test_multi_hop_chain;
    "test fibonacci" >:: test_fibonacci_network;
    "test event delivery order" >:: test_event_delivery_order
  ]

let () = run_test_tt_main suite
