open OUnit2
open Emu
open Utils

let test_span_tree _ctx =
  (* exclude external node from consideration *)
  let node_count = Net.size (Sim.create_net ~root_id:0) - 1 in 
  for root_id = 0 to node_count - 1 do
    let digest = Sim.run ~root_id in
    let final_state = Digest.final_node_state ~node_id:root_id digest in
    Printf.printf "root %d final_state: %s\n" root_id (pp_list final_state);
    assert_equal ~msg:(Printf.sprintf "root %d count" root_id)
      8 (List.nth final_state 2);
    assert_equal ~msg:(Printf.sprintf "root %d max_node_id" root_id)
      7 (List.nth final_state 3)
  done


let suite =
  "span tree tests" >::: [
    "test span tree" >:: test_span_tree;
  ]

let () = run_test_tt_main suite