open OUnit2
open Utils

module IntMap = Map.Make(Int)

let tap_assert_leaf_on_setup ~(leaves: Leaf.leaf array) ~leaf_idx ~expected_value digest =
  let leaf = leaves.(leaf_idx) in
  
  let leaf_state = Emu.Digest.final_node_state 
    ~node_id:leaf.id digest in
	
  Printf.printf "leaf(%d) state: %s\n" 
    leaf.id (pp_list leaf_state);
	
  assert_equal [1; expected_value] leaf_state;
  
  assert_equal [1] (get_out_stream leaf.id leaf.output.setup_ok digest);
  
  
  digest


let tap_assert_leaf_on_auth ~(leaves: Leaf.leaf array) ~leaf_idx digest =
  let leaf = leaves.(leaf_idx) in
  
  let leaf_state = Emu.Digest.final_node_state 
    ~node_id:leaf.id digest in
	
  let out_stream = get_out_stream leaf.id leaf.output.auth_fail digest in
	
  Printf.printf "leaf(%d) state: %s\n" 
    leaf.id (pp_list leaf_state);

  Printf.printf "leaf(%d) auth_fail stream: %s\n" 
    leaf.id (pp_list out_stream);
	
  assert_equal [0; 0] leaf_state;
  
  assert_equal [1] out_stream;
  
  digest  





let test_setup_password _ctx =
  (* Create network *)
  let l = 4 in (* number of layers 0..(l-1) aka password length *)
  let n = 5 in (* number of digits 0..n-1 *)
  
  let Net.{net; ext; leaves; _ } = 
    Net.make_net ~n ~l () in
  Printf.printf "\n===Setup password testing===\n\n";
  Printf.printf "Number of leaves: %d\n" (Array.length leaves);

  (* Create initial snapshot *)
  let init_snap = Emu.Runtime.create net in
  
  let leaf_index p = List.fold_left (fun acc d -> acc * n + d) 0 p in
  
  (* Process passwords lazily using Seq.fold_left *)
  let _ =
    password_seq ~n ~l
    |> Seq.take 4  (* Only take first 4 passwords *)
    |> Seq.fold_left (fun digest password ->
         let leaf_idx = leaf_index password in
         let value = 1000 + leaf_idx in
         
         Printf.printf "\nTesting %s -> leaf %d\n" 
           (String.concat "" (List.map string_of_int password)) leaf_idx;
         
         digest
         |> setup_password ~ext ~password ~value
         |> tap_assert_leaf_on_setup ~leaves ~leaf_idx ~expected_value:value
       ) (Emu.Digest.empty init_snap)
  in
  
  ()

let test_auth_password _ctx =
  (* Create network *)
  let l = 4 in (* number of layers 0..(l-1) aka password length *)
  let n = 5 in (* number of digits 0..n-1 *)
  
  let Net.{net; ext; leaves; _ } = 
    Net.make_net ~n ~l () in
  Printf.printf "\n===Auth password testing===\n\n";
  Printf.printf "Number of leaves: %d\n" (Array.length leaves);

  (* Create initial snapshot *)
  let init_snap = Emu.Runtime.create net in
  
  let leaf_index p = List.fold_left (fun acc d -> acc * n + d) 0 p in
  
  (* Process passwords lazily using Seq.fold_left *)
  let _ =
    password_seq ~n ~l
    |> Seq.take 30  (* Only take first 30 passwords *)
    |> Seq.fold_left (fun digest password ->
         let leaf_idx = leaf_index password in
         
         Printf.printf "\nTesting %s -> leaf %d\n" 
           (String.concat "" (List.map string_of_int password)) leaf_idx;
         
         digest
         |> auth_password ~ext ~password
         |> tap_assert_leaf_on_auth ~leaves ~leaf_idx
       ) (Emu.Digest.empty init_snap)
  in
  
  ()

let test_setup_password_states _ctx =
  let l = 4 in
  let n = 5 in
  
  let Net.{net; ext; leaves; _ } = Net.make_net ~n ~l () in
  let init_snap = Emu.Runtime.create net in
  
  let leaf0 = leaves.(0) in
  
  (* Take snapshot before setup *)
  let net_before = init_snap.net in
  
  (* Run setup *)
  let digest = setup_password ~ext ~password:[0;0;0;0] ~value:42 (Emu.Digest.empty init_snap) in
  let net_after = digest.final_snapshot.net in
  
  (* Compare states *)
  let diff = Emu.Tool.distinct_states net_before net_after in
  
  (* Verify only leaf 0 changed *)
  assert_equal 1 (Emu.Tool.total_differences diff);
  assert_equal true (IntMap.mem leaf0.id diff.changed);
  
  (* Print diff for debugging *)
  Emu.Tool.print_state_diff diff;
  
  (* Verify specific change *)
  match Emu.Tool.get_node_diff leaf0.id diff with
  | Some (`Changed (before, after)) ->
      assert_equal [0;0] before;
      assert_equal [1;42] after
  | _ -> 
      failwith "Leaf 0 should show as changed"

let test_setup_and_auth_states _ctx =
  let l = 4 in
  let n = 5 in
  
  let Net.{net; ext; leaves; observer; _ } = Net.make_net ~n ~l () in
  let init_snap = Emu.Runtime.create net in
  
  (* Save network state before any operations *)
  let net_initial = init_snap.net in
  let leaf0 = leaves.(0) in
  
  Printf.printf "\n=== Phase 1: Setup Password ===\n";
  (* Run setup *)
  let digest_setup = setup_password ~ext ~password:[0;0;0;0] ~value:42 (Emu.Digest.empty init_snap) in
  let net_after_setup = digest_setup.final_snapshot.net in
  
  (* Compare states after setup *)
  let diff_setup = Emu.Tool.distinct_states net_initial net_after_setup in
  
  Printf.printf "\n--- State changes after setup ---\n";
  Emu.Tool.print_state_diff diff_setup;
  
  (* Verify only leaf 0 changed during setup *)
  assert_equal 1 (Emu.Tool.total_differences diff_setup);
  assert_equal true (IntMap.mem leaf0.id diff_setup.changed);
  
  (* Verify specific change in leaf 0 *)
  let _ = match Emu.Tool.get_node_diff leaf0.id diff_setup with
  | Some (`Changed (before, after)) ->
      assert_equal [0;0] before;
      assert_equal [1;42] after;
      Printf.printf "✓ Leaf 0 correctly programmed: %s → %s\n" 
        (pp_list before) (pp_list after)
  | _ -> 
      failwith "Leaf 0 should show as changed"
  in
  
  Printf.printf "\n=== Phase 2: Authenticate ===\n";
  (* Run auth with correct password *)
  let digest_auth = auth_password ~ext ~password:[0;0;0;0] digest_setup in
  let net_after_auth = digest_auth.final_snapshot.net in
  
  (* Compare states after auth *)
  let diff_auth = Emu.Tool.distinct_states net_after_setup net_after_auth in
  
  Printf.printf "\n--- State changes after auth (should be none) ---\n";
  Emu.Tool.print_state_diff diff_auth;
  
  (* Verify NO state changes during auth - tunnel self-destructed *)
  assert_equal 0 (Emu.Tool.total_differences diff_auth);
  Printf.printf "✓ No state changes detected - tunnel properly self-destructed\n";
  
  (* Verify auth succeeded by checking output stream *)
  let value_stream = get_out_stream leaf0.id leaf0.output.value digest_auth in
  Printf.printf "Leaf 0 emitted value: %s\n" (pp_list value_stream);
  assert_equal [42] value_stream;
  
  Printf.printf "\n=== Phase 3: Second Auth with wrong password (auth should fail) ===\n";
  let digest_second_auth = auth_password ~ext ~password:[0;0;0;1] digest_auth in
  let net_after_second = digest_second_auth.final_snapshot.net in
  
  (* Compare states after second auth (should still be no changes) *)
  let diff_second = Emu.Tool.distinct_states net_after_auth net_after_second in
  assert_equal 0 (Emu.Tool.total_differences diff_second);
  
  (* Verify second auth fails (no value emitted) *)
  let leaf1 = leaves.(1) in
  let auth_fail_stream = get_out_stream leaf1.id leaf1.output.auth_fail digest_second_auth in
  Emu.Digest.print_out_stream ~label:"Leaf0 out" leaf1.id digest_second_auth;
  Emu.Digest.print_in_stream ~label:"Observer in" observer.id digest_second_auth;
  assert_equal [1] auth_fail_stream;
  
  Printf.printf "\n✓ All tests passed: setup works, auth works once, tunnel self-destructs!\n";
  ()

let stress_test _ctx =
  let l = 4 in
  let n = 5 in
  
  let Net.{net; ext; leaves; _ } = Net.make_net ~n ~l () in
  let init_snap = Emu.Runtime.create net in
  
  let leaf0 = leaves.(0) in
  let leaf1 = leaves.(1) in
  let leaf2 = leaves.(2) in
  
  Printf.printf "\n=== STRESS TEST: Multiple Operations in One Avalanche ===\n";
  
  (* Define a sequence of operations *)
  let operations = [
    (* Setup leaf0 with value 100 *)
    ("setup", [0;0;0;0], 100);
    (* Auth leaf0 - should emit 100 *)
    ("auth", [0;0;0;0], 100);
    (* Setup leaf1 with value 200 *)
    ("setup", [0;0;0;1], 200);
    (* Auth leaf1 - should emit 200 *)
    ("auth", [0;0;0;1], 200);
    (* Setup leaf2 with value 300 *)
    ("setup", [0;0;0;2], 300);
    (* Auth leaf2 - should emit 300 *)
    ("auth", [0;0;0;2], 300);
    (* Auth leaf0 again - should emit 100 again *)
    ("auth", [0;0;0;0], 100);
    (* Auth leaf1 again - should emit 200 again *)
    ("auth", [0;0;0;1], 200); 
  ] in
  
 
  (* Create schedule from operations *)
  let schedule = 
    List.fold_left (fun acc (op, password, value) ->
      match op with
      | "setup" ->
          acc @ setup_messages ~ext ~password ~value
      | "auth" ->
          acc @ auth_messages ~ext ~password
      | _ -> acc
    ) [] operations
  in
  
  Printf.printf "Total messages in schedule: %d\n" (List.length schedule);
  print_schedule ~label:"Schedule" schedule;
  (* Run the entire schedule in one avalanche *)
  let digest = Emu.Runtime.run ~schedule init_snap in
  
  (* Verify results *)
  Printf.printf "\n=== Results ===\n";
  
  (* Check leaf0 emitted 100 twice *)
  let leaf0_value = get_out_stream leaf0.id leaf0.output.value digest in
  Emu.Digest.print_out_stream ~label:"Leaf0 value" leaf0.id digest; 
  assert_equal [100; 100] leaf0_value;  (* Two successful auths *)
  
  (* Check leaf1 emitted 200 twice *)
  let leaf1_value = get_out_stream leaf1.id leaf1.output.value digest in
  Emu.Digest.print_out_stream ~label:"Leaf1 value" leaf1.id digest; 
  assert_equal [200; 200] leaf1_value;  (* Two successful auths *)
  
  (* Check leaf2 emitted 300 once *)
  let leaf2_value = get_out_stream leaf2.id leaf2.output.value digest in
  Emu.Digest.print_out_stream ~label:"Leaf2 value" leaf2.id digest; 
  assert_equal [300] leaf2_value; 

  
  (* Check final state of leaves *)
  let leaf0_final = Emu.Digest.final_node_state ~node_id:leaf0.id digest in
  let leaf1_final = Emu.Digest.final_node_state ~node_id:leaf1.id digest in
  let leaf2_final = Emu.Digest.final_node_state ~node_id:leaf2.id digest in
  
  Printf.printf "\n=== Final States ===\n";
  Printf.printf "Leaf0: %s\n" (pp_list leaf0_final);
  Printf.printf "Leaf1: %s\n" (pp_list leaf1_final);
  Printf.printf "Leaf2: %s\n" (pp_list leaf2_final);
  
  (* All leaves should still have their values *)
  assert_equal [1;100] leaf0_final;
  assert_equal [1;200] leaf1_final;
  assert_equal [1;300] leaf2_final;
  
  let diff = Emu.Tool.distinct_states init_snap.net digest.final_snapshot.net in
  Emu.Tool.print_state_diff diff;
  
  
  Printf.printf "\n✓ Stress test passed: %d operations processed in one avalanche!\n" 
    (List.length operations);
  () 
 
let test_setup_tunnel _ctx =
  let l = 4 in
  let n = 5 in
  
  let { Net.net; ext; _ } = Net.make_net ~n ~l () in
  let init_snap = Emu.Runtime.create net in
  let prev_net = ref init_snap.net in
  let _ =
    init_snap
    |> Emu.Runtime.run ~schedule:(digit_messages ~ext ~password:[0;0;0;0])
    |> tap (fun (d: Emu.Digest.t) -> 
         let diff = Emu.Tool.distinct_states init_snap.net d.final_snapshot.net in
		 Printf.printf "\n===Setup tunnel - built===\n";
         Emu.Tool.print_state_diff diff;
         (* Assert every changed node has expected state *)
         IntMap.iter (fun _ (_, final_state) ->
           assert (final_state = [1; 0]) (* tunnel before destroy state in setup phase *)
         ) diff.changed
       )
    |> (fun (d: Emu.Digest.t) -> 
	     Emu.Runtime.run ~schedule:[value_message ~ext ~value:42] d.final_snapshot
		)
    |> tap (fun (d: Emu.Digest.t) -> 
         let diff = Emu.Tool.distinct_states init_snap.net d.final_snapshot.net in
		 Printf.printf "\n===Setup tunnel - destroyed===\n";
         Emu.Tool.print_state_diff diff;
		 prev_net := d.final_snapshot.net
       )
	|> (fun (d: Emu.Digest.t) -> (* first three auth digits extend the tunnel *)
	     Emu.Runtime.run ~schedule:(auth_messages ~ext ~password:[0;0;0;]) d.final_snapshot
		)
    |> tap (fun (d: Emu.Digest.t) -> 
         let diff = Emu.Tool.distinct_states init_snap.net d.final_snapshot.net in
		 Printf.printf "\n===Auth tunnel - built===\n";
         Emu.Tool.print_state_diff diff;
       )
	|> (fun (d: Emu.Digest.t) -> (* Last auth digit destroys the tunnel *)
	     Emu.Runtime.run ~schedule:(auth_messages ~ext ~password:[0]) d.final_snapshot
		)
    |> tap (fun (d: Emu.Digest.t) -> (* state should be the same as before auth process started *)
         let diff = Emu.Tool.distinct_states init_snap.net d.final_snapshot.net in
		 Printf.printf "\n===Auth tunnel - destroyed===\n";
         Emu.Tool.print_state_diff diff;
		 assert_equal true (Emu.Tool.are_identical !prev_net d.final_snapshot.net)
       )
	   
  in 
  ()

let suite =
  "digital locker tests" >::: [
    "test setup password" >:: test_setup_password;
    "test auth passwordd" >:: test_auth_password;
    "test setup password states" >:: test_setup_password_states;
    "test setup and auth password states" >:: test_setup_and_auth_states;
    "stress_test" >:: stress_test;
    "test setup tunnel" >:: test_setup_tunnel;
    (* "test sending digit > N on setup phase redirect it to auth out_port " >:: corrupt tunnel; *)
  ]

let () = run_test_tt_main suite