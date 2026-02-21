(* runtime.ml *)

open Snapshot

module IntMap = Map.Make(Int)

(* ------------------------------------------------------------- *)
(* Unified event type                                            *)
(* ------------------------------------------------------------- *)

type event = {
  src      : int;
  out_port : int;
  payload  : int;
}

(* ------------------------------------------------------------- *)
(* Create initial snapshot                                       *)
(* ------------------------------------------------------------- *)

let create ?(lifespan = 100) net =
  Snapshot.make ~lifetime:lifespan ~net ()

(* ------------------------------------------------------------- *)
(* Enqueue                                                       *)
(* ------------------------------------------------------------- *)

let enqueue (ev : event) snap =
  if snap.lifetime <= 0 then
    failwith "runtime: lifetime exceeded (immortal activity detected)";

  let queue = Queue.enqueue (ev.src, ev.out_port, ev.payload) snap.queue in
  snap
  |> Snapshot.with_queue queue
  |> Snapshot.with_lifetime (snap.lifetime - 1)

(* ------------------------------------------------------------- *)
(* Deliver an event                                              *)
(* ------------------------------------------------------------- *)

let deliver_event snap (ev : event) =
  let subscribers = Net.subscribers snap.net ev.src ev.out_port in

  List.fold_left
    (fun (snap, acc_steps) (dst_id, in_port) ->

       let net_after, outs =
         Net.deliver snap.net dst_id in_port ev.payload
       in

       let snap = Snapshot.with_net snap net_after in
	   
       (* Preserve handler emission order when enqueuing into the global FIFO. *)
       let snap =
         List.fold_left
           (fun snap (out_p, v) ->
              enqueue { src = dst_id; out_port = out_p; payload = v } snap)
           snap
           outs
       in

       let step =
         Step.make
           ~src_node:ev.src
           ~dest_node:dst_id
           ~in_port
           ~payload:ev.payload
           ~emitted:outs
           ~snapshot:snap
       in

       (snap, step :: acc_steps)
    )
    (snap, [])
    subscribers

(* ------------------------------------------------------------- *)
(* One internal step                                             *)
(* ------------------------------------------------------------- *)

let step snap =
  match Queue.dequeue snap.queue with
  | None -> None
  | Some ((src, out_port, payload), queue') ->
      let snap = Snapshot.with_queue queue' snap in
      let ev = { src; out_port; payload } in
      let snap', steps = deliver_event snap ev in
      Some (snap', steps)

let make_step = step

(* ------------------------------------------------------------- *)
(* Avalanche: run until queue is empty                           *)
(* ------------------------------------------------------------- *)

let rec run_avalanche snap history =
  match make_step snap with
  | None -> (snap, history)
  | Some (snap', steps) ->
      run_avalanche snap' (steps @ history)

(* ------------------------------------------------------------- *)
(* Run a sequence of avalanches                                  *)
(* ------------------------------------------------------------- *)

let rec run_avalanches ?stop_when snap history = function
  | [] ->
      Digest.make ~initial_snapshot:snap ~history
  | ev :: rest ->
      (* enforce quiescence-only injection *)
      if not (Queue.is_empty snap.queue) then
        failwith "runtime: injection only allowed at quiescence (queue not empty)";
	  
      Net.validate_emit_source snap.net ev.src ev.out_port;
	  
      let snap = enqueue ev snap in
      let snap, history = run_avalanche snap history in

      (* NEW: termination check *)
      match stop_when with
      | Some f when f snap ->
          Digest.make ~initial_snapshot:snap ~history
      | _ ->
          run_avalanches ?stop_when snap history rest


(* ------------------------------------------------------------- *)
(* Public API                                                    *)
(* ------------------------------------------------------------- *)

let run ?stop_when ~schedule initial_snapshot =
  run_avalanches ?stop_when initial_snapshot [] schedule

