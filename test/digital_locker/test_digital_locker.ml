open OUnit2

let pp_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"

let test_digital_locker _ctx =
  (* Create network *)
  let Net.{net; ext; root_router; leaves; observer; payload; unlocker} = Net.make_net ~n:2 () in
  
  (* Create initial snapshot *)
  let init_snap = Emu.Runtime.create ~lifespan:1000 net in
  
  (* Check initial state *)
  let router_initial_state = Emu.Digest.node_state root_router.id init_snap in
  Printf.printf "Router initial state: %s\n" (pp_list router_initial_state);
  
  (* Run first schedule - reset both tokens *)
  let digest1 = Emu.Runtime.run init_snap ~schedule:[
    { src = ext.id; out_port = ext.output.setup_reset; payload = 1 };
    { src = ext.id; out_port = ext.output.auth_reset; payload = 1 };
	{ src = ext.id; out_port = ext.output.payload; payload = 42 };
  ] in
  
  (* Check final state after reset *)
  let router_final_state = Emu.Digest.final_node_state ~node_id:root_router.id digest1 in
  Printf.printf "Router after reset: %s\n" (pp_list router_final_state);
  
  (* Verify expected behavior - root router should have [1;1] after reset *)
  assert_equal [1;1] router_final_state;
  
  let digest2 = Emu.Runtime.run digest1.final_snapshot ~schedule:[
    { src = ext.id; out_port = ext.output.setup; payload = 1 };
  ] in
  

  let leaf1_setup_ok = 
    Emu.Digest.node_out_stream_on_port 
      ~node_id:leaves.(1).id 
      ~out_port:leaves.(1).output.setup_ok 
      digest2 
  in
  assert_equal [1] leaf1_setup_ok;
  
  (* Check observer got setup_ok from leaf 0 *)
  let setup_ok_stream =
    Emu.Digest.node_out_stream_on_port 
      ~node_id:observer.id 
      ~out_port:observer.output.setup_ok 
      digest2
  in
  assert_equal [1] setup_ok_stream;
  (* Test auth phase - correct digit for leaf 0 *)
  let digest3 = Emu.Runtime.run digest2.final_snapshot ~schedule:[
    { src = ext.id; out_port = ext.output.auth; payload = 0 };
  ] in
  
  let leaf0_auth_fail =
    Emu.Digest.node_out_stream_on_port 
      ~node_id:leaves.(0).id 
      ~out_port:leaves.(0).output.auth_fail 
      digest3
  in
  assert_equal [1] leaf0_auth_fail;
  Printf.printf "leaf0_auth_fail: %s\n" (pp_list leaf0_auth_fail);
  
  let auth_fail_stream =
    Emu.Digest.node_out_stream_on_port 
      ~node_id:observer.id 
      ~out_port:observer.output.auth_fail 
      digest3
  in
  assert_equal [1] auth_fail_stream;
  
  let digest4 = Emu.Runtime.run digest3.final_snapshot ~schedule:[
    { src = ext.id; out_port = ext.output.auth_reset; payload = 1 };
    { src = ext.id; out_port = ext.output.auth; payload = 1 };
  ] in
  
  let leaf1_auth_ok =
    Emu.Digest.node_out_stream_on_port 
      ~node_id:leaves.(1).id 
      ~out_port:leaves.(1).output.auth_ok 
      digest4
  in
  assert_equal [1] leaf1_auth_ok;
  Printf.printf "leaf1_auth_ok: %s\n" (pp_list leaf1_auth_ok);
  
  let unlocker_auth_ok =
    Emu.Digest.node_in_stream 
      ~node_id:unlocker.id 
      digest4
  in
  assert_equal [1] unlocker_auth_ok;
  
  let auth_ok_stream =
    Emu.Digest.node_out_stream_on_port 
      ~node_id:observer.id 
      ~out_port:observer.output.auth_ok 
      digest4
  in
  assert_equal [1] auth_ok_stream;
  
  let payload_value =
    Emu.Digest.node_out_stream_on_port 
      ~node_id:payload.id 
      ~out_port:payload.output.value 
      digest4
  in
  assert_equal [42] payload_value
  
  (* OUnit test must return unit *)

let suite =
  "digital locker tests" >::: [
    "test router reset" >:: test_digital_locker;
  ]

let () = run_test_tt_main suite