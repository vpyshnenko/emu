open OUnit2
open Emu
open Utils

let test_span_tree _ctx =
  let builder = Netbuilder.create () in

  (* 1. Declare nodes (IDs are autoincremented as 0, 1, 2, 3) *)
  let n0 = Netbuilder.add_node builder in
  let n1 = Netbuilder.add_node builder in
  let n2 = Netbuilder.add_node builder in
  let n3 = Netbuilder.add_node builder in

  (* 2. Wire connections (Dynamic ports naturally start at 1 on both sides) *)
  Netbuilder.connect builder n0 n1; (* Node 0 (Port 1) <-> Node 1 (Port 1) *)
  Netbuilder.connect builder n0 n2; (* Node 0 (Port 2) <-> Node 2 (Port 1) *)
  Netbuilder.connect builder n1 n3; (* Node 1 (Port 2) <-> Node 3 (Port 1) *)
  Netbuilder.connect builder n2 n3; (* Node 2 (Port 2) <-> Node 3 (Port 2) *)

  (* 3. Finalize into an executable network simulation *)
  let net = Netbuilder.finalize builder n0 in
  
  Utils.print_routing_map net;
  let init_snap = Emu.Runtime.create net in
  let digest1 = Emu.Runtime.run init_snap ~schedule:[
    { src = -1; out_port = 0; payload = 1 };
  ] in
  let final_state = Digest.final_node_state ~node_id: n3 digest1 in
  Printf.printf "final_state: %s\n" (pp_list final_state)
  (* in () *)


let suite =
  "span tree tests" >::: [
    "test span tree" >:: test_span_tree;
  ]

let () = run_test_tt_main suite