open Emu

let pp_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"
  
let make_idx_gen init =
  let next = ref init in
  fun () ->
    let current = !next in
    incr next; (* Idiomatic OCaml helper for: next := !next + 1 *)
    current

(** Prints the entire global routing table of the network *)
let print_routing_map (net : Net.t) : unit =
  Net.IntPairMap.iter (fun (src_id, out_port_id) subscribers ->
    let subs_str = 
      subscribers
      |> List.map (fun (dst_id, in_port) -> 
           Printf.sprintf "Node %d (Port %d)" dst_id in_port)
      |> String.concat "; "
    in
    Printf.printf "Node %d (Port %d) -> [%s]\n" src_id out_port_id subs_str
  ) net.routing