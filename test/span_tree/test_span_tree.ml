open OUnit2

open Emu
open Span_tree

let test_span_tree_cycle _ctx =
  let node_count = Emu.Net.size Net.cycle_net in 
  for root_id = 0 to node_count - 1 do
    let net = Netbuilder.attach_ext Net.cycle_net root_id in
    let init_snap = Emu.Runtime.create net in
    let digest = Emu.Runtime.run init_snap ~schedule:[
      { src = -1; out_port = 0; payload = [1] };
      { src = -1; out_port = 1; payload = [1] };
    ] in
    let final_state = Emu.Digest.final_node_state ~node_id:root_id digest in
    (* Printf.printf "root %d final_state: %s\n" root_id (pp_list final_state); *)
    assert_equal ~msg:(Printf.sprintf "root %d count" root_id)
      8 (List.nth final_state Layout.mem.count);
    assert_equal ~msg:(Printf.sprintf "root %d max_node_id" root_id)
      7 (List.nth final_state Layout.mem.max_node_id);
    assert_equal ~msg:(Printf.sprintf "root %d eccentricity" root_id)
      3 (List.nth final_state Layout.mem.eccentricity)
  done

let test_span_tree_linear _ctx =
  (* exclude external node from consideration *)
  let eccentricity_snock: int Snoc.t = Snoc.create () in
  let node_count = Emu.Net.size Net.linear_net in
  let net_radius = ref max_int in
  for root_id = 0 to node_count - 1 do
    let net = Netbuilder.attach_ext Net.linear_net root_id in
    let init_snap = Emu.Runtime.create net in
    let digest = Emu.Runtime.run init_snap ~schedule:[
      { src = -1; out_port = 0; payload = [1] };
      { src = -1; out_port = 1; payload = [1] };
    ] in
    let final_state = Emu.Digest.final_node_state ~node_id:root_id digest in
	let eccentricity = List.nth final_state Layout.mem.eccentricity in
	if eccentricity < !net_radius then
	  net_radius := eccentricity;
	Snoc.add eccentricity_snock eccentricity; 
    (* Printf.printf "root %d final_state: %s\n" root_id (pp_list final_state); *)
    assert_equal ~msg:(Printf.sprintf "root %d count" root_id)
      9 (List.nth final_state 2);
    assert_equal ~msg:(Printf.sprintf "root %d max_node_id" root_id)
      8 (List.nth final_state 3)
  done;
  Printf.printf "net radius =  %d\n" !net_radius;
  assert_equal [8; 7; 6; 5; 4; 5; 6; 7; 8] (Snoc.to_list eccentricity_snock)
  

let suite =
  "span tree tests" >::: [
    "test span tree cycle" >:: test_span_tree_cycle;
    "test span tree linear" >:: test_span_tree_linear;
  ]

let () = run_test_tt_main suite