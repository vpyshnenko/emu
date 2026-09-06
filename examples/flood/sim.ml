open Emu
open Flood

let net = Flood.Net.make_linear_net 20
(* let net = Flood.Net.make_ring_net 20 *)
(* let net = Flood.Net.cycle_net *)

let init_snap = Snapshot.make ~net ~max_queue_length:10000 ()

let send idA idB =
   let dst = Runtime.run init_snap ~schedule:[
    { src = idA; out_port = Layout.output.tx; payload = [idB; 1] };
   ] in 
   Printf.printf "Total steps: %d\n" (Digest.total_steps dst);
   Digest.print_all_states dst;
   dst
   

  
