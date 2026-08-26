open Emu
open Ping_pong

let () = 
  let nodeA_id = 0 in
  let nodeB_id = 4 in
  let value = 42 in
  let digest = Sim.run nodeA_id nodeB_id value in
  Digest.print_out_stream ~label:"destNode out stream" nodeB_id digest
