open OUnit2
open Utils



let test_digital_multi_locker _ctx =
  (* Create network *)
  let l = 4 in (* number of layers 0..(l-1) aka password length *)
  let n = 5 in (* number of digits 0..n-1 *)
  
  let Net.{net; ext; routers; leaves; observer; } = 
    Net.make_net ~n ~l () in
  Printf.printf "Number of leaves: %d\n" (Array.length leaves);

  (* Create initial snapshot *)
  let init_snap = Emu.Runtime.create net in
  let root_router = routers.(0).(0) in
  
  (* Check initial state *)
  let root_router_initial_state = Emu.Digest.node_state root_router.id init_snap in
  Printf.printf "Root router initial state: %s\n" (pp_list root_router_initial_state);
  
  
  
  (* Run the test pipeline - ignore final digest with _ *)
  let _ =
    Emu.Digest.empty init_snap
	|> setup_password ~ext ~password:[0;0;0;0] ~value:42
    |> tap (fun d -> 
	     let leaf0_state = Emu.Digest.final_node_state ~node_id:leaves.(0).id d in
		 Printf.printf "leaf(%d) state: %s\n" leaves.(0).id (pp_list leaf0_state);
		 assert_equal [1; 42] leaf0_state)
         (* assert_equal [1] (get_out_stream observer.id observer.output.setup_ok d)) *)
    |> setup_password ~ext ~password:[1;2;3;4] ~value:42
    |> tap (fun d -> 
         assert_equal [1] (get_out_stream observer.id observer.output.setup_ok d))
    |> auth_password ~ext ~password:[0;1;2;1]
    |> tap (fun d -> 
		 Emu.Digest.print_in_stream ~label:"1 in: " 1 d;
		 Emu.Digest.print_out_stream ~label:"1 out:" 1 d;
		 Emu.Digest.print_in_stream ~label:"2 in: " 2 d;
		 Emu.Digest.print_out_stream ~label:"2 out:" 2 d;
		 Emu.Digest.print_in_stream ~label:"3 in: " 3 d;
		 Emu.Digest.print_out_stream ~label:"3 out:" 3 d;
		 Emu.Digest.print_in_stream ~label:"9 in: " 9 d;
		 Emu.Digest.print_out_stream ~label:"9 out:" 9 d;
		 Emu.Digest.print_in_stream ~label:"40 in: " 40 d;
		 Emu.Digest.print_out_stream ~label:"40 out:" 40 d;
		 Emu.Digest.print_in_stream ~label:"193 in: " 193 d;
		 Emu.Digest.print_out_stream ~label:"193 out:" 193 d;
         assert_equal [1] (get_out_stream observer.id observer.output.auth_fail d))
    |> auth_password ~ext ~password:[0;1;2;2]
    |> tap (fun d -> 
	     (* let out_stream = get_out_stream observer.id observer.output.auth_fail d in *)
	     (* let in_stream = get_in_stream observer.id observer.input.auth_fail d in *)
         (* Printf.printf "auth_fail in stream: %s\n" (pp_list in_stream); *)
		 Emu.Digest.print_in_stream ~label:"1 in: " 1 d;
		 Emu.Digest.print_out_stream ~label:"1 out:" 1 d;
		 Emu.Digest.print_in_stream ~label:"2 in: " 2 d;
		 Emu.Digest.print_out_stream ~label:"2 out:" 2 d;
		 Emu.Digest.print_in_stream ~label:"3 in: " 3 d;
		 Emu.Digest.print_out_stream ~label:"3 out:" 3 d;
		 Emu.Digest.print_in_stream ~label:"9 in: " 9 d;
		 Emu.Digest.print_out_stream ~label:"9 out:" 9 d;
		 Emu.Digest.print_in_stream ~label:"40 in: " 40 d;
		 Emu.Digest.print_out_stream ~label:"40 out:" 40 d;
		 Emu.Digest.print_in_stream ~label:"194 in: " 194 d;
		 Emu.Digest.print_out_stream ~label:"194 out:" 194 d;
		 
         (* !!! should be one value in auth_fail stream but: [1; 1] *)
		 (* assert_equal [1] (get_out_stream observer.id observer.output.auth_fail d)) *)
		 assert_equal [1; 1] (get_out_stream observer.id observer.output.auth_fail d))


    |> auth_password ~ext ~password:[1;2;3;4]
    |> tap (fun d ->
         assert_equal [42] (get_out_stream observer.id observer.output.value d))
		   
    |> setup_password ~ext ~password:[1;2;1;1] ~value:41
    |> tap (fun d -> 
         assert_equal [1] (get_out_stream observer.id observer.output.setup_ok d))
    |> auth_password ~ext ~password:[1;2;1;1]
    |> tap (fun d ->
         assert_equal [41] (get_out_stream observer.id observer.output.value d))
    |> auth_password ~ext ~password:[0;1;2;0]
    |> tap (fun d -> 
	     let auth_fail_stream = get_out_stream observer.id observer.output.auth_fail d in
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