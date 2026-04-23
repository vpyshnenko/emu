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

let flush_message ~ext =
  [ { src = ext.id; out_port = ext.output.flush; payload = 1 } ]

  

(* Helper function for tap - since OUnit doesn't have tap *)
let tap f x = f x; x

(* emit ~ext ~values:[1;3;2;1] *)
let emit ~ext ~values (digest : Emu.Digest.t) : Emu.Digest.t = 
  Emu.Runtime.run digest.final_snapshot ~schedule:((data_messages ~ext ~values) @ (flush_message ~ext))
