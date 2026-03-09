open OUnit2
open Router
open Ext
module Net = struct
  include Net  (* This refers to test/digital_locker/net.ml *)
end

let pp_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"

let test_digital_locker _ctx =
  (* Create network *)
  let {net; ext; root_router} = make_net () in
  
  (* Create initial snapshot *)
  let init_snap = Runtime.create ~lifespan:1000 net in
  
  (* Check initial state *)
  let router_initial_state = Digest.node_state ~node_id:root_router.id init_snap in
  Printf.printf "Router initial state: %s\n" (pp_list router_initial_state);
  
  (* Run first schedule - reset both tokens *)
  let digest1 = Runtime.run init_snap ~schedule:[
    { Runtime.src = ext.id; out_port = ext.output.reset_setup; payload = 1 };
    { Runtime.src = ext.id; out_port = ext.output.reset_auth; payload = 1 };
  ] in
  
  (* Check final state after reset *)
  let router_final_state = Digest.final_node_state ~node_id:root_router.id digest1 in
  Printf.printf "Router after reset: %s\n" (pp_list router_final_state);
  
  (* Verify expected behavior - root router should have [1;1] after reset *)
  assert_equal [1;1] router_final_state;
  
  (* Print node IDs for debugging *)
  Printf.printf "Ext ID: %d\n" ext.id;
  Printf.printf "Router ID: %d\n" root_router.id;
  
  (* OUnit test must return unit *)
  ()

let suite =
  "digital locker tests" >::: [
    "test router reset" >:: test_digital_locker;
  ]

let () = run_test_tt_main suite