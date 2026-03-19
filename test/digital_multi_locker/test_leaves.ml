open OUnit2
open Utils

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
  
  (* assert_equal [1] out_stream; *)
  
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
  let init_snap = Emu.Runtime.create ~lifespan:1000 net in
  
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
  let init_snap = Emu.Runtime.create ~lifespan:1000 net in
  
  let leaf_index p = List.fold_left (fun acc d -> acc * n + d) 0 p in
  
  (* Process passwords lazily using Seq.fold_left *)
  let _ =
    password_seq ~n ~l
    |> Seq.take 10  (* Only take first 4 passwords *)
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

let suite =
  "digital locker tests" >::: [
    "test setup password" >:: test_setup_password;
    "test auth passwordd" >:: test_auth_password;
  ]

let () = run_test_tt_main suite