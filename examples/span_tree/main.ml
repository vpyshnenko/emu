open Emu
open Span_tree

let () = 
  let root_id = 0 in
  let digest = Sim.run root_id in
  let final_state = Digest.final_node_state ~node_id:root_id digest in
  Printf.printf "final_state: %s\n" (Utils.pp_list final_state)