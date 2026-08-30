open Emu

let n = 9
let root_id = 4
let net = Netbuilder.attach_ext (Ping_pong.Net.make_linear_net n)
let init_snap = Runtime.create net

let dst_stp = Runtime.run init_snap ~schedule:[
    { src = Netbuilder.ext_stp_id; out_port = root_id; payload = [1] };
]

let send idA idB value =
   let dst = Runtime.run dst_stp.final_snapshot ~schedule:[
    { src = Netbuilder.ext_id; out_port = idA; payload = [idB; value] };
   ] in 
   Digest.print_in_stream ~label:"root [in]:" Netbuilder.ext_id dst
   
  (* Utils.print_routing_map net; *)
  (* let net = Netbuilder.attach_ext Net.cycle_net in *)

let run_stp root_id =
  Runtime.run init_snap ~schedule:[
      { src = Netbuilder.ext_stp_id; out_port = root_id; payload = [1] };
  ]

  
