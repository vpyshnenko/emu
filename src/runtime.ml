(* runtime.ml *)

open Snapshot

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

let create net =
  Snapshot.make ~net ()

(* ------------------------------------------------------------- *)
(* Enqueue                                                       *)
(* ------------------------------------------------------------- *)

let enqueue (ev : event) (snap : Snapshot.t) : Snapshot.t =
  let queue = Queue.enqueue (ev.src, ev.out_port, ev.payload) snap.queue in
  snap
  |> Snapshot.with_queue queue

(* ------------------------------------------------------------- *)
(* Deliver an event                                              *)
(* - appends steps directly into global history Snoc             *)
(* - returns per-event steps as a list for step-by-step debugging *)
(*   (no reversal; list order is internal accumulation order)    *)
(* ------------------------------------------------------------- *)

let deliver_event
    ~(history : Step.t Snoc.t)
    (snap : Snapshot.t)
    (ev : event)
  : Snapshot.t * Step.t list
  =
  let subscribers = Net.subscribers snap.net ev.src ev.out_port in

  List.fold_left
    (fun (snap, steps_acc) (dst_id, in_port) ->
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

       (* Global chronological history *)
       Snoc.add history step;

       (* Per-event debug steps list (kept simple; not reversed into chronological) *)
       (snap, step :: steps_acc)
    )
    (snap, [])
    subscribers

(* ------------------------------------------------------------- *)
(* One internal step                                             *)
(* Returns (new_snapshot, per-event steps list)                  *)
(* ------------------------------------------------------------- *)

let step ~(history : Step.t Snoc.t) (snap : Snapshot.t)
  : (Snapshot.t * Step.t list) option
  =
  match Queue.dequeue snap.queue with
  | None -> None
  | Some ((src, out_port, payload), queue') ->
      let snap = Snapshot.with_queue queue' snap in
      let ev = { src; out_port; payload } in
      let snap', steps = deliver_event ~history snap ev in
      Some (snap', steps)

let make_step = step

(* ------------------------------------------------------------- *)
(* Avalanche: run until queue is empty                           *)
(* ------------------------------------------------------------- *)

let run_avalanche 
    ~(history : Step.t Snoc.t) 
    ?(max_steps = 1000)  (* Maximum steps allowed in this avalanche *)
    (snap : Snapshot.t)
  : Snapshot.t
  =
  let rec loop steps_remaining snap =
    if steps_remaining <= 0 then
      failwith "AVALANCHE: Maximum steps exceeded - possible infinite loop";
    
    match make_step ~history snap with
    | None -> snap
    | Some (snap', _steps) ->
        loop (steps_remaining - 1) snap'
  in
  loop max_steps snap

(* ------------------------------------------------------------- *)
(* Run a sequence of avalanches                                  *)
(* - threads the true initial snapshot separately                *)
(* ------------------------------------------------------------- *)

let rec run_avalanches
    ?stop_when
    ~(initial_snapshot : Snapshot.t)
    ~(history : Step.t Snoc.t)
    (snap : Snapshot.t)
    (schedule : event list)
  : Digest.t
  =
  match schedule with
  | [] ->
      Digest.make
        ~initial_snapshot
        ~final_snapshot:snap
        ~history

  | ev :: rest ->
      (* enforce quiescence-only injection *)
      if not (Queue.is_empty snap.queue) then
        failwith "runtime: injection only allowed at quiescence (queue not empty)";

      Net.validate_emit_source snap.net ev.src ev.out_port;

      let snap = enqueue ev snap in
      let snap = run_avalanche ~history snap in

      (* termination check *)
      match stop_when with
      | Some f when f snap ->
          Digest.make
            ~initial_snapshot
            ~final_snapshot:snap
            ~history
      | _ ->
          run_avalanches ?stop_when ~initial_snapshot ~history snap rest

(* ------------------------------------------------------------- *)
(* Public API                                                    *)
(* ------------------------------------------------------------- *)

let run ?stop_when ~schedule (initial_snapshot : Snapshot.t) : Digest.t =
  let history : Step.t Snoc.t = Snoc.create () in
  run_avalanches
    ?stop_when
    ~initial_snapshot
    ~history
    initial_snapshot
    schedule