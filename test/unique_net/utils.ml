open Emu.Runtime
open Ext

let pp_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"
  
let get_out_stream node_id port_id digest = 
  Emu.Digest.node_out_stream_on_port ~node_id:node_id ~out_port: port_id digest
  
let get_in_stream node_id port_id digest = 
  Emu.Digest.node_in_stream_on_port_src ~node_id:node_id ~in_port: port_id digest
  
let data_messages ~ext ~values = 
  List.map (fun value ->
    { src = ext.id; out_port = ext.output.data; payload = value }
  ) values
  
let reset_message ~ext =
  [ { src = ext.id; out_port = ext.output.reset; payload = 1 } ]

let reset ~ext (digest : Emu.Digest.t) : Emu.Digest.t = 
  Emu.Runtime.run digest.final_snapshot ~schedule:(reset_message ~ext)
(* Helper function for tap - since OUnit doesn't have tap *)
let tap f x = f x; x

(* emit ~ext ~values:[1;3;2;1] *)
let emit ~ext ~values (digest : Emu.Digest.t) : Emu.Digest.t = 
  Emu.Runtime.run digest.final_snapshot ~schedule:(data_messages ~ext ~values)
  
let rec is_ordered = function
  | [] -> true
  | [_] -> true
  | x :: (y :: _ as tail) -> x <= y && is_ordered tail

let generate_balanced_sorting_tree_list n =
  let size = (1 lsl n) - 1 in
  
  let rec process queue acc =
    match queue with
    | [] -> List.rev acc
    | (low, high) :: rest ->
        if low > high then process rest acc
        else
          let mid = (low + high) / 2 in
          process (rest @ [(low, mid - 1); (mid + 1, high)]) (mid :: acc)
  in
  
  process [(1, size)] []