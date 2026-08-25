open Emu
open Ping_pong

let () = 
  let nodeA_id = 0 in
  let nodeB_id = 4 in
  let digest = Sim.run nodeA_id nodeB_id  in
  Digest.print_out_stream ~label:"nodeA out stream" nodeA_id digest
