open Emu

let root_id = 4
let net = Netbuilder.attach_ext (Ping_pong.Net.make_linear_net 9)
(* let net = Netbuilder.attach_ext Ping_pong.Net.cycle_net *)

let init_snap = Runtime.create net

let dst_stp = Runtime.run init_snap ~schedule:[
    { src = Netbuilder.ext_stp_id; out_port = root_id; payload = [1] };
]

let send idA idB value =
   let dst = Runtime.run dst_stp.final_snapshot ~schedule:[
    { src = Netbuilder.ext_id; out_port = idA; payload = [idB; value] };
   ] in 
   Digest.print_in_stream ~label:"root [in]:" Netbuilder.ext_id dst;
   Printf.printf "Total steps: %d\n" (Digest.total_steps dst);
   dst
   
  (* Utils.print_routing_map net; *)
  (* let net = Netbuilder.attach_ext Net.cycle_net in *)

let run_stp root_id =
  Runtime.run init_snap ~schedule:[
      { src = Netbuilder.ext_stp_id; out_port = root_id; payload = [1] };
  ]
  
let ping idA idB =
   let dst = Runtime.run dst_stp.final_snapshot ~schedule:[
    { src = Netbuilder.ext_ping_id; out_port = idA; payload = [idB] };
   ] in 
   Digest.print_in_stream ~label:"ext [in]:" Netbuilder.ext_id dst;
   Digest.print_in_stream ~label:"ext_ping [in]:" Netbuilder.ext_ping_id dst;
   Printf.printf "Total steps: %d\n" (Digest.total_steps dst);
   dst

  
