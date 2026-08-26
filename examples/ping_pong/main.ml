open Emu
open Ping_pong

let () = 
  let digest = Sim.run 3 in
  Digest.print_in_stream ~label:"ext_node [in]" (-1) digest
