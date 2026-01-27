(* digest.ml *)

open Snapshot

type t = {
  initial_snapshot : Snapshot.t;
  history : Step.t list;
}

let make ~initial_snapshot ~history : t =
  { initial_snapshot; history }

(* ------------------------------------------------------------- *)
(* Basic metrics                                                 *)
(* ------------------------------------------------------------- *)

let total_steps (history : Step.t list) : int =
  List.length history

(* ------------------------------------------------------------- *)
(* Snapshot helpers                                              *)
(* ------------------------------------------------------------- *)

let final_snapshot (d : t) : Snapshot.t =
  match d.history with
  | step :: _ -> Step.snapshot step
  | [] -> d.initial_snapshot

let node_state node_id snap =
  let node = Net.get_node snap.net node_id in
  node.state


let final_node_state ~node_id (d : t) : State.t =
  let snap = final_snapshot d in
  node_state node_id snap

(* ------------------------------------------------------------- *)
(* Input stream (per incoming port)                              *)
(* ------------------------------------------------------------- *)

let node_in_stream_on_port ~node_id ~in_port (d : t) : int list =
  d.history
  |> List.rev  (* chronological order: oldest → newest *)
  |> List.filter (Step.matches_input ~node_id ~in_port)
  |> List.map Step.payload
  
let node_in_stream ~node_id (d : t) : int list =
  d.history
  |> List.rev  (* chronological order: oldest → newest *)
  |> List.filter (Step.matches_in ~node_id)
  |> List.map Step.payload

(* ------------------------------------------------------------- *)
(* Output stream (all outgoing ports)                            *)
(* ------------------------------------------------------------- *)

let node_out_stream ~node_id (d : t) : int list =
  d.history
  |> List.rev
  |> List.filter (Step.is_for_node ~node_id)
  |> List.map Step.emitted
  |> List.flatten
  |> List.map snd   (* drop out_port, keep payload *)

(* ------------------------------------------------------------- *)
(* Output stream for a specific outgoing port                    *)
(* ------------------------------------------------------------- *)

let node_out_stream_on_port ~node_id ~out_port (d : t) : int list =
  d.history
  |> List.rev
  |> List.filter (Step.is_for_node ~node_id)
  |> List.map Step.emitted
  |> List.flatten
  |> List.filter (fun (p, _) -> p = out_port)
  |> List.map snd

(* ------------------------------------------------------------- *)
(* Edge stream: values sent from src to dst                      *)
(* ------------------------------------------------------------- *)

let node_edge_stream ~src ~dst (d : t) : int list =
  d.history
  |> List.rev
  |> List.filter (fun step ->
       Step.src step = src && Step.dest step = dst)
  |> List.map Step.payload

(* ------------------------------------------------------------- *)
(* All values sent by a node (any port)                          *)
(* ------------------------------------------------------------- *)

let node_sent_values ~node_id d =
  d.history
  |> List.rev
  |> List.filter (fun step -> Step.src step = node_id)
  |> List.map Step.payload
