open OUnit2
open Instructions

let make_vm () =
  Vm.create ~stack_capacity:10 ~max_steps:10

let pp_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"

(* ------------------------------------------------------------ *)
(* Test: Fibonacci network                                      *)
(* ------------------------------------------------------------ *)

let test_fibonacci_network _ctx =
  let vm = make_vm () in

  (* Node A: state=[0], handler on in_port=0, emits on out_port=0 *)
  let nodeA =
    Node.create ~state:[0] ~vm ()
    |> Node.add_default_handler [Add; Emit]
  in

  (* Node B *)
  let nodeB =
    Node.create ~state:[0] ~vm ()
    |> Node.add_default_handler [Add; Emit]
  in

  (* Node C: collects Fibonacci sequence *)
  let nodeC =
    Node.create ~vm ()
    |> Node.add_default_handler [Emit]
  in

  (* Node D: countdown node *)
  let limit = 3 in
  let nodeD =
    Node.create ~state:[limit] ~vm ()
    |> Node.add_default_handler [
         HaltIfEq (1, 0);
         Emit;
         Pop;
         PushConst (-1);
         Add;
       ]
  in

  (* Build network using new add_node API *)
  let net0 = Net.create () in
  let net1, idA = Net.add_node nodeA net0 in
  let net2, idB = Net.add_node nodeB net1 in
  let net3, idC = Net.add_node nodeC net2 in
  let net4, idD = Net.add_node nodeD net3 in
  Printf.printf "idA %d idB %d idC %d idD %d\n" idA idB idC idD;

  (* Connect using default ports (0 → 0) *)
let net =
  net4
  |> fun n -> Net.connect ~src:idA ~dst:idD n ()
  |> fun n -> Net.connect ~src:idD ~dst:idB n ()
  |> fun n -> Net.connect ~src:idB ~dst:idA n ()
  |> fun n -> Net.connect ~src:idA ~dst:idC n ()
  |> fun n -> Net.connect ~src:idB ~dst:idC n ()

  in

  let init_snap =
    Runtime.create ~lifespan:100 net
  in

  (* Start by sending payload=1 into node B (idB) on in_port=0 *)
  let digest =
    Runtime.run
      ~bang:{ dst = idB; event_name = "default"; payload = 1 }
      init_snap
  in

  (* Streams *)
  let nodeA_out_stream = Digest.node_out_stream ~node_id:idA digest in
  let nodeB_out_stream = Digest.node_out_stream ~node_id:idB digest in
  let nodeC_out_stream = Digest.node_out_stream ~node_id:idC digest in
  let nodeD_out_stream = Digest.node_out_stream ~node_id:idD digest in
  
  let nodeA_sent_values = Digest.node_sent_values ~node_id:idA digest in
  let nodeB_sent_values = Digest.node_sent_values ~node_id:idB digest in
  let nodeC_sent_values = Digest.node_sent_values ~node_id:idC digest in
  let nodeD_sent_values = Digest.node_sent_values ~node_id:idD digest in
  
  let nodeA_in_stream = Digest.node_in_stream ~node_id:idA ~in_port:0 digest in
  let nodeB_in_stream = Digest.node_in_stream ~node_id:idB ~in_port:0 digest in
  let nodeC_in_stream = Digest.node_in_stream ~node_id:idC ~in_port:0 digest in
  let nodeD_in_stream = Digest.node_in_stream ~node_id:idD ~in_port:0 digest in
  
  let edge_AD_stream = Digest.node_edge_stream ~src:idA ~dst:idD digest in
  let edge_DB_stream = Digest.node_edge_stream ~src:idD ~dst:idB digest in
  let edge_BA_stream = Digest.node_edge_stream ~src:idB ~dst:idA digest in
  let edge_AC_stream = Digest.node_edge_stream ~src:idA ~dst:idC digest in
  let edge_BC_stream = Digest.node_edge_stream ~src:idB ~dst:idC digest in
  
  let nodeC_state = Digest.final_node_state ~node_id:idC digest in

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
  assert_equal fib_seq nodeC_out_stream;
  assert_equal [] nodeC_sent_values;
  
  Printf.printf "NodeC emitted values: %s\n" (pp_list nodeC_out_stream)



let suite =
  "runtime tests" >::: [
    "test fibonacci" >:: test_fibonacci_network;
  ]

let () = run_test_tt_main suite
