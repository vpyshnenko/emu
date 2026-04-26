open OUnit2
open Utils



let test_sorting_net _ctx =
  (* Create network *)
  let l = 8 in (* number of layers 0..(l-1) aka sorting net capasity *)
  
  let Net.{ net; ext; sink } = 
    Net.make_net ~l () in
	
  Printf.printf "\nTotally: %d nodes\n" (Emu.Net.size net);
  

  (* Create initial snapshot *)
  let init_snap = Emu.Runtime.create net in
  
  (* Run the test pipeline - ignore final digest with _ *)
  let _ =
    Emu.Digest.empty init_snap
    (* |> emit ~ext ~values:[2;3;1;2;1;] *)
    (* |> emit ~ext ~values:[2;6;4;2;1;] *)
    (* |> emit ~ext ~values:[1; 2; 3; 4] *)
    (* |> emit ~ext ~values:[1; 2; 3] *)
    |> emit ~ext ~values:[26; 61; 37; 42; 12;35;67;45;54;34;23;89;45;67;87;32;43;54;65;53;43;42;64;85;61;25;27;27;45;69;67;68;79;90;65;53]
    |> tap (fun d -> 
	     let in_stream = get_in_stream 2 0 d in
	     let out_stream = get_out_stream sink.id sink.output.out d in
		 let state = Emu.Digest.final_node_state ~node_id:4 d in
		 assert_equal true (is_ordered out_stream);
         Printf.printf "in stream: %s\n" (pp_list in_stream);
         Printf.printf "out stream: %s\n" (pp_list out_stream);
		 Printf.printf "state: %s\n" (pp_list state)
         (* assert_equal [1] (get_out_stream sink.id sink.output.out d) *)
	   )
  in ()


let suite =
  "sorting net tests" >::: [
    "simple sorting net" >:: test_sorting_net;
  ]

let () = run_test_tt_main suite