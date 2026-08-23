open OUnit2
open Emu
open Utils

let test_span_tree _ctx =
  let root_id = 0 in
  
  let digest1 = Sim.run root_id in
  let final_state = Digest.final_node_state ~node_id: root_id digest1 in
  Printf.printf "final_state: %s\n" (pp_list final_state)
  (* in () *)


let suite =
  "span tree tests" >::: [
    "test span tree" >:: test_span_tree;
  ]

let () = run_test_tt_main suite