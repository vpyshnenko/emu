open OUnit2
open Emu.Runtime

let pp_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"
  
let get_stream node_id port_id digest = 
  Emu.Digest.node_out_stream_on_port ~node_id:node_id ~out_port: port_id digest
  
(* Setup a password and value, starting from a digest *)
let setup_password 
    ~ext 
    ~password      (* int list: the password digits *)
    ~value         (* int: the secret to store *)
    (digest : Emu.Digest.t) 
  : Emu.Digest.t =
  
  (* Create messages for each password digit *)
  let digit_messages = List.map (fun digit ->
    Ext.{ src = ext.id; out_port = ext.output.setup_data; payload = digit }
  ) password in
  
  (* Create final message with the value *)
  let value_message = 
    { src = ext.id; out_port = ext.output.setup_data; payload = value } in
  
  (* Run all messages in sequence *)
  Emu.Runtime.run digest.final_snapshot ~schedule:(digit_messages @ [value_message])

(* Authenticate with a password, starting from a digest *)
let auth_password
    ~ext
    ~password      (* int list: the password digits *)
    (digest : Emu.Digest.t)
  : Emu.Digest.t =
  
  (* Create messages for each password digit *)
  let auth_messages = List.map (fun digit ->
    Ext.{ src = ext.id; out_port = ext.output.auth_data; payload = digit }
  ) password in
  
  (* Run all auth messages *)
  Emu.Runtime.run digest.final_snapshot ~schedule:auth_messages

(* Helper function for tap - since OUnit doesn't have tap *)
let tap f x = f x; x

let test_digital_multi_locker _ctx =
  (* Create network *)
  let l = 4 in (* number of layers 0..(l-1) aka password length *)
  let n = 5 in (* number of digits 0..n-1 *)
  
  let Net.{net; ext; routers; leaves; observer; } = 
    Net.make_net ~n ~l () in
  Printf.printf "Number of leaves: %d\n" (Array.length leaves);

  (* Create initial snapshot *)
  let init_snap = Emu.Runtime.create ~lifespan:1000 net in
  let root_router = routers.(0).(0) in
  
  (* Check initial state *)
  let root_router_initial_state = Emu.Digest.node_state root_router.id init_snap in
  Printf.printf "Root router initial state: %s\n" (pp_list root_router_initial_state);
  
  (* Run the test pipeline - ignore final digest with _ *)
  let _ =
    Emu.Digest.empty init_snap
    |> setup_password ~ext ~password:[1;2;3;4] ~value:42
    |> tap (fun d -> 
         assert_equal [1] (get_stream observer.id observer.output.setup_ok d))
    |> auth_password ~ext ~password:[0;1;2;1]
    |> tap (fun d -> 
         assert_equal [1] (get_stream observer.id observer.output.auth_fail d))
    |> auth_password ~ext ~password:[0;1;2;2]
    |> tap (fun d -> 
	     let out_stream = get_stream observer.id observer.output.auth_fail d in
         Printf.printf "auth_fail stream: %s\n" (pp_list out_stream);
         (* !!! should be one value in auth_fail stream but: [1; 1] *)
		 assert_equal [1] (get_stream observer.id observer.output.auth_fail d))

    |> auth_password ~ext ~password:[1;2;3;4]
    |> tap (fun d ->
         assert_equal [42] (get_stream observer.id observer.output.value d))
		   
    |> setup_password ~ext ~password:[1;2;1;1] ~value:41
    |> tap (fun d -> 
         assert_equal [1] (get_stream observer.id observer.output.setup_ok d))
    |> auth_password ~ext ~password:[1;2;1;1]
    |> tap (fun d ->
         assert_equal [41] (get_stream observer.id observer.output.value d))
    |> auth_password ~ext ~password:[0;1;2;0]
    |> tap (fun d -> 
	     let auth_fail_stream = get_stream observer.id observer.output.auth_fail d in
         Printf.printf "auth_fail stream: %s\n" (pp_list auth_fail_stream);
         assert_equal [1] auth_fail_stream)
  in
  
  (* Test returns unit *)
  ()

let suite =
  "digital locker tests" >::: [
    "test digital multi locker" >:: test_digital_multi_locker;
  ]

let () = run_test_tt_main suite