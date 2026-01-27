(* runtime.ml *)

open Snapshot

type bang = {
  dst : int;          (* destination node id *)
  in_port_id : int;      (* destination incoming port id *)
  payload : int;
}

module IntMap = Map.Make(Int)

let god_node_id = 0

(* ------------------------------------------------------------- *)
(* Create initial snapshot                                       *)
(* ------------------------------------------------------------- *)

let create ?(lifespan = 100) net =
  Snapshot.make ~lifetime:lifespan ~net ()

(* ------------------------------------------------------------- *)
(* Enqueue                                                       *)
(* ------------------------------------------------------------- *)

let enqueue ~src ~out_port ~payload snap =
  if snap.lifetime <= 0 then
    failwith "runtime: lifetime exceeded (immortal activity detected)";

  let queue = Queue.enqueue (src, out_port, payload) snap.queue in
  snap
  |> Snapshot.with_queue queue
  |> Snapshot.with_lifetime (snap.lifetime - 1)

(* ------------------------------------------------------------- *)
(* Deliver an event                                              *)
(* ------------------------------------------------------------- *)

let deliver_event snap ~src ~out_port ~payload =
  let subscribers = Net.subscribers snap.net src out_port in

  List.fold_left
    (fun (snap, acc_steps) (dst_id, in_port) ->

       (* Deliver to destination node *)
       let net_after, outs =
         Net.deliver snap.net dst_id in_port payload
       in

       (* Update snapshot with new net *)
       let snap = Snapshot.with_net snap net_after in
	   
       (* Revert outs before enquering to provide early first ordering *)
	   let outs = List.rev outs in

       (* Enqueue outgoing events from this node *)
       let snap =
         List.fold_left
           (fun snap (out_p, v) ->
              enqueue ~src:dst_id ~out_port:out_p ~payload:v snap)
           snap
           outs
       in

       (* Build Step.t *)
       let step =
         Step.make
           ~src_node:src
           ~dest_node:dst_id
           ~in_port:in_port
           ~payload
           ~emitted:outs
           ~snapshot:snap
       in

       (snap, step :: acc_steps)
    )
    (snap, [])
    subscribers

(* ------------------------------------------------------------- *)
(* One step of execution                                         *)
(* ------------------------------------------------------------- *)

let step snap =
  match Queue.dequeue snap.queue with
  | None -> None
  | Some ((src, out_port, payload), queue') ->
      let snap = Snapshot.with_queue queue' snap in
      let snap', steps =
        deliver_event snap ~src ~out_port ~payload
      in
      Some (snap', steps)

(* ------------------------------------------------------------- *)
(* Run until queue is empty                                      *)
(* ------------------------------------------------------------- *)

let make_step snap = step snap
 

let rec run_loop snap history =
  match step snap with
  | None ->
      Digest.make ~initial_snapshot:snap ~history
  | Some (snap', steps) ->
      run_loop snap' (steps @ history)

(* ------------------------------------------------------------- *)
(* Public run API with mandatory ~bang                           *)
(* ------------------------------------------------------------- *)

let inject_bang ~bang initial_snapshot = 
  let net =
	Net.connect {
      from = (god_node_id, 0);
      to_  = (bang.dst, bang.in_port_id);
    } initial_snapshot.net

  in

  (* Update snapshot with virtual edge *)
  let snap = Snapshot.with_net initial_snapshot net in

  (* Enqueue initial event from god node *)
  let snap =
    enqueue
      ~src:god_node_id
      ~out_port:0
      ~payload:bang.payload
      snap
  in
     snap

let run ~bang initial_snapshot =
  let snap = inject_bang ~bang initial_snapshot in
  (* Run simulation *)
  run_loop snap []