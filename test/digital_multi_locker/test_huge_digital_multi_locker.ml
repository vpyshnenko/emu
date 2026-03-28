open OUnit2
open Utils

module IntMap = Map.Make(Int)

let post_inc r = 
  let old = !r in
  r := old + 1;
  old  (* Return old value *)

let test_huge_digital_multi_locker _ctx =
  
  (* Create huge network: !!! Test runs for 7 sec!!! *)
  let l = 6 in (* number of layers 0..(l-1) aka password length *)
  let n = 10 in (* number of digits 0..n-1 *)
  
  let Net.{net; ext; observer; leaves; _ } = 
    Net.make_net ~n ~l () in
  Printf.printf "Number of leaves: %d\n" (Array.length leaves);

  (* Create initial snapshot *)
  let init_snap = Emu.Runtime.create net in
  
  (* Run the test pipeline - ignore final digest with _ *)
  let _ =
    init_snap
    |> Emu.Runtime.run ~schedule:(digit_messages ~ext ~password:[0;1;2;3;4;5])
    |> tap (fun (d: Emu.Digest.t) -> 
         let diff = Emu.Tool.distinct_states init_snap.net d.final_snapshot.net in
		 Printf.printf "\n===Setup tunnel - built===\n";
         Emu.Tool.print_state_diff diff;
         (* Assert every changed node has expected state *)
		 let i = ref 0 in
         IntMap.iter (fun _ (_, final_state) ->
           assert (final_state = [1; post_inc i]) (* tunnel before destroy state in setup phase *)
         ) diff.changed
       )
    |> (fun (d: Emu.Digest.t) -> 
	     Emu.Runtime.run ~schedule:[value_message ~ext ~value:42] d.final_snapshot
		)
    |> auth_password ~ext ~password:[0;1;2;3;4;5]
    |> tap (fun d ->
         assert_equal [42] (get_out_stream observer.id observer.output.value d))
  in
  
  (* Test returns unit *)
  ()

let suite =
  "digital locker tests" >::: [
    "test huge digital multi locker" >:: test_huge_digital_multi_locker;
  ]

let () = run_test_tt_main suite