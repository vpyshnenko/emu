open OUnit2
open Router
open Ext

(* let pp_list lst = *)
  (* "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]" *)

(* ------------------------------------------------------------ *)
(* Digital Vault (B=3, L=3)                                      *)
(* Password = address sequence                                   *)
(* ------------------------------------------------------------ *)

let test_digital_locker _ctx =
  (* Create router with 2 digits (or whatever number you need) *)
  let router = make_router ~n:2 () in
  let ext = make_ext ()  in
  
  let nb, ( --> ) = Builder.Net.create () in

  let idExt = nb.add_node ext.node in
  let idRouter  = nb.add_node router.node in
  
  (ext.id, ext.output.reset_setup) --> (router.id, router.input.reset_setup);
  
  
  (* let net = nb.finalize () in *)
  
  Printf.printf "idExt: %d\n" idExt;
  Printf.printf "idRouter: %d\n" idRouter
  
  (* OUnit test must return unit *)

let suite =
  "digital locker tests" >::: [
    "test router creation" >:: test_digital_locker;
  ]

let () = run_test_tt_main suite