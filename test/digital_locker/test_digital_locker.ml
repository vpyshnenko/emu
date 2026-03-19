open OUnit2

let pp_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"

let test_digital_locker _ctx =
  (* Create network *)
  let Net.{net; ext; routers; leaves; observer; payload; unlocker} = 
    Net.make_net ~n:10 ~l:4 () in
  Printf.printf "Number of leaves: %d\n" (Array.length leaves);

  (* Create initial snapshot *)
  let init_snap = Emu.Runtime.create net in
  let root_router = routers.(0).(0) in
  
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
  let root_router_final_state = Emu.Digest.final_node_state ~node_id:root_router.id digest1 in
  Printf.printf "Router after reset: %s\n" (pp_list root_router_final_state);
  
  (* Verify expected behavior - root router should have [1;1] after reset *)
  assert_equal [1;1] root_router_final_state;
  
  let digest2 = Emu.Runtime.run digest1.final_snapshot ~schedule:[
    { src = ext.id; out_port = ext.output.setup_data; payload = 1 };
    { src = ext.id; out_port = ext.output.setup_data; payload = 2 };
    { src = ext.id; out_port = ext.output.setup_data; payload = 2 };
    { src = ext.id; out_port = ext.output.setup_data; payload = 9 };
  ] in


  (* Check observer got setup_ok *)
  let setup_ok_stream =
    Emu.Digest.node_out_stream_on_port 
      ~node_id:observer.id 
      ~out_port:observer.output.setup_ok 
      digest2
  in
  assert_equal [1] setup_ok_stream;
  Printf.printf "setup_ok_stream: %s\n" (pp_list setup_ok_stream);
  
  (* Test auth phase - correct digit for leaf 0 *)
  let digest3 = Emu.Runtime.run digest2.final_snapshot ~schedule:[
    { src = ext.id; out_port = ext.output.auth_data; payload = 0 };
    { src = ext.id; out_port = ext.output.auth_data; payload = 1 };
    { src = ext.id; out_port = ext.output.auth_data; payload = 1 };
    { src = ext.id; out_port = ext.output.auth_data; payload = 9 };
  ] in
  
  
  let auth_fail_stream =
    Emu.Digest.node_out_stream_on_port 
      ~node_id:observer.id 
      ~out_port:observer.output.auth_fail 
      digest3
  in
  assert_equal [1] auth_fail_stream;
  Printf.printf "auth_fail_stream: %s\n" (pp_list auth_fail_stream);
  
  let digest4 = Emu.Runtime.run digest3.final_snapshot ~schedule:[
    { src = ext.id; out_port = ext.output.auth_reset; payload = 1 };
	
    { src = ext.id; out_port = ext.output.auth_data; payload = 1 };
    { src = ext.id; out_port = ext.output.auth_data; payload = 2 };
    { src = ext.id; out_port = ext.output.auth_data; payload = 2 };
    { src = ext.id; out_port = ext.output.auth_data; payload = 9 };
  ] in
  
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
  Printf.printf "auth_ok_stream: %s\n" (pp_list auth_ok_stream);
  assert_equal [1] auth_ok_stream;
  
  let payload_value =
    Emu.Digest.node_out_stream_on_port 
      ~node_id:payload.id 
      ~out_port:payload.output.value 
      digest4
  in
  Printf.printf "payload_value_stream: %s\n" (pp_list payload_value);
  assert_equal [42] payload_value
  
  (* OUnit test must return unit *)

let suite =
  "digital locker tests" >::: [
    "test router reset" >:: test_digital_locker;
  ]

let () = run_test_tt_main suite