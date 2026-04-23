open OUnit2
open Utils



let test_sorting_net _ctx =
  (* Create network *)
  let l = 2 in (* number of layers 0..(l-1) aka sorting net capasity *)
  
  let Net.{ net; ext; sink } = 
    Net.make_net ~l () in
	
  Printf.printf "\nTotally: %d nodes\n" (Emu.Net.size net);
  

  (* Create initial snapshot *)
  let init_snap = Emu.Runtime.create net in
  
  (* Run the test pipeline - ignore final digest with _ *)
  let _ =
    Emu.Digest.empty init_snap
    |> emit ~ext ~values:[2;3;1;2;1;]
    |> tap (fun d -> 
	     let out_stream = get_out_stream sink.id sink.output.out d in
         Printf.printf "out stream: %s\n" (pp_list out_stream)
         (* assert_equal [1] (get_out_stream sink.id sink.output.out d) *)
	   )
  in ()


let suite =
  "sorting net tests" >::: [
    "simple sorting net" >:: test_sorting_net;
  ]

let () = run_test_tt_main suite