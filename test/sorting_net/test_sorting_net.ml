open OUnit2
open Utils



let test_sorting_net _ctx =
  (* Create network *)
  let l = 3 in (* number of layers 0..(l-1) aka sorting net capasity *)
  
  let Net.{ net; ext; routers; sink } = 
    Net.make_net ~l () in
	
  Printf.printf "\nTotally: %d nodes\n" (Emu.Net.size net);
  
  let root_router = routers.(0).(0) in
  
  (* Create initial snapshot *)
  let init_snap = Emu.Runtime.create net in
  
  (* Run the test pipeline - ignore final digest with _ *)
  let _ =
    Emu.Digest.empty init_snap
    (* |> emit ~ext ~values:[2;3;1;2;1;] *)
    (* |> emit ~ext ~values:[2;6;4;2;1;] *)
    (* |> emit ~ext ~values:[1; 2; 3; 4] *)
    (* |> emit ~ext ~values:[1; 2; 3] *)
    |> emit ~ext ~values:[4; 2; 6; 1; 3; 5; 7; ] (* sorting net preconfiguration with balanced values *)
	    |> tap (fun d -> 
	     let in_stream = get_in_stream root_router.id  root_router.input.data d in
	     let out_stream = get_out_stream sink.id sink.output.out d in
	     let out_overflow_stream = get_out_stream sink.id sink.output.overflow d in
		 assert_equal true (is_ordered out_stream);
         Printf.printf "in stream: %s\n" (pp_list in_stream);
         Printf.printf "out stream: %s\n" (pp_list out_stream);
         Printf.printf "out overflow stream: %s\n" (pp_list out_overflow_stream);
	   )
    |> emit ~ext ~values:[1; 2; 3; 4; 5; 6; 7; 7; 6; 5; 4; 3; 2; 1;] (* most extreme case covering full range *)
    |> tap (fun d -> 
	     let in_stream = get_in_stream root_router.id  root_router.input.data d in
	     let out_stream = get_out_stream sink.id sink.output.out d in
	     let out_overflow_stream = get_out_stream sink.id sink.output.overflow d in
		 assert_equal true (is_ordered out_stream);
         Printf.printf "in stream: %s\n" (pp_list in_stream);
         Printf.printf "out stream: %s\n" (pp_list out_stream);
         Printf.printf "out overflow stream: %s\n" (pp_list out_overflow_stream);
	   )
    |> emit ~ext ~values: [8; -1; 9]
    |> tap (fun d -> 
	     let in_stream = get_in_stream root_router.id  root_router.input.data d in
	     let out_stream = get_out_stream sink.id sink.output.out d in
	     let out_overflow_stream = get_out_stream sink.id sink.output.overflow d in
		 assert_equal true (is_ordered out_stream);
         Printf.printf "in stream: %s\n" (pp_list in_stream);
         Printf.printf "out stream: %s\n" (pp_list out_stream);
         Printf.printf "out overflow stream: %s\n" (pp_list out_overflow_stream);
         (* assert_equal [1] (get_out_stream sink.id sink.output.out d) *)
	   )
  in ()


let suite =
  "sorting net tests" >::: [
    "simple sorting net" >:: test_sorting_net;
  ]

let () = run_test_tt_main suite