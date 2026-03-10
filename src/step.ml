(* step.ml *)

type t = {
  src_node : int;
  dest_node : int;
  in_port  : int;
  payload  : int;
  emitted  : (int * int) list;   (* (out_port, payload) *)
  snapshot : Snapshot.t;
}

let make ~src_node ~dest_node ~in_port ~payload ~emitted ~snapshot =
  { src_node; dest_node; in_port; payload; emitted; snapshot }

let src s = s.src_node
let dest s = s.dest_node
let in_port s = s.in_port
let payload s = s.payload
let emitted s = s.emitted
let snapshot s = s.snapshot

let is_for_node ~node_id s =
  s.dest_node = node_id

let is_from_node ~node_id s =
  s.src_node = node_id

let matches_in ~node_id s =
  s.dest_node = node_id

let matches_input ~node_id ~in_port s =
  s.dest_node = node_id && s.in_port = in_port
