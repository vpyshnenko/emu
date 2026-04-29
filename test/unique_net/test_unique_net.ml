open OUnit2
open Utils



let test_unique_net _ctx =
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
    |> emit ~ext ~values:[4; 2; 2; 0; 1; 3; 5; 7; 3; 6; 5; 7;] 
    |> tap (fun d -> 
	     let in_stream = get_in_stream root_router.id  root_router.input.data d in
	     let out_stream = get_out_stream sink.id sink.output.out d in
	     let out_saturated_stream = get_out_stream sink.id sink.output.saturated d in
		 let sink_state = Emu.Digest.final_node_state ~node_id:sink.id d in
		 (* assert_equal out_stream [2; 1; 3; 4; 5; 7]; *)
	     let out_overflow_stream = get_out_stream sink.id sink.output.overflow d in
         Printf.printf "in stream: %s\n" (pp_list in_stream);
         Printf.printf "out stream: %s\n" (pp_list out_stream);
         Printf.printf "out overflow stream: %s\n" (pp_list out_overflow_stream);
         Printf.printf "out saturated stream: %s\n" (pp_list out_saturated_stream);
         Printf.printf "sink state: %s\n" (pp_list sink_state)
	   )
    |> reset ~ext
    |> emit ~ext ~values:[4; 2; 6; 1; 3; 5; 7; ] (* exhausted stream that saturates the unique net *)
    |> tap (fun d -> 
	     let in_stream = get_in_stream root_router.id  root_router.input.data d in
	     let out_stream = get_out_stream sink.id sink.output.out d in
	     let out_saturated_stream = get_out_stream sink.id sink.output.saturated d in
		 let sink_state = Emu.Digest.final_node_state ~node_id:sink.id d in
		 (* assert_equal out_stream [2; 1; 3; 4; 5; 7]; *)
	     let out_overflow_stream = get_out_stream sink.id sink.output.overflow d in
         Printf.printf "in stream: %s\n" (pp_list in_stream);
         Printf.printf "out stream: %s\n" (pp_list out_stream);
         Printf.printf "out overflow stream: %s\n" (pp_list out_overflow_stream);
         Printf.printf "out saturated stream: %s\n" (pp_list out_saturated_stream);
         Printf.printf "sink state: %s\n" (pp_list sink_state)
	   )


  in ()


let suite =
  "unique net tests" >::: [
    "simple unique net" >:: test_unique_net;
  ]

let () = run_test_tt_main suite