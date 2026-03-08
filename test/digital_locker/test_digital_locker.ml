open OUnit2
open Router
open Ext

let pp_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"


let test_digital_locker _ctx =
  (* Create router with 2 digits (or whatever number you need) *)
  let ext = make_ext ()  in
  let router = make_root_router ~n:2 in
  
  let nb, ( --> ) = Builder.Net.create () in

  let idExt = nb.add_node ext.node in
  let idRouter = nb.add_node router.node in
  
  (ext.id, ext.output.reset_setup) --> (router.id, router.input.reset_setup);
  (ext.id, ext.output.reset_auth) --> (router.id, router.input.reset_auth);
  
  let net = nb.finalize () in
  let init_snap = Runtime.create ~lifespan:1000 net in
  
  let router_initial_state = Digest.node_state router.id init_snap in
  Printf.printf "router initial state: %s\n" (pp_list router_initial_state);
  
  
  let digest1 = Runtime.run init_snap ~schedule:[
    { Runtime.src = ext.id; out_port = ext.output.reset_setup; payload = 1 };
    { Runtime.src = ext.id; out_port = ext.output.reset_auth; payload = 1 };
  ] in
  
  let router_final_state = Digest.final_node_state ~node_id:router.id digest1 in
  Printf.printf "router final state: %s\n" (pp_list router_final_state);
  
  
  Printf.printf "idExt: %d\n" idExt;
  Printf.printf "idRouter: %d\n" idRouter
  
  (* OUnit test must return unit *)

let suite =
  "digital locker tests" >::: [
    "test router creation" >:: test_digital_locker;
  ]

let () = run_test_tt_main suite