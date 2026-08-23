(* snoc.ml *)
module StdQueue = Stdlib.Queue

type 'a t = 'a StdQueue.t

let create () : 'a t =
  StdQueue.create ()

let is_empty (q : 'a t) : bool =
  StdQueue.is_empty q

let length (q : 'a t) : int =
  StdQueue.length q

(* Append at end, preserves order *)
let add (q : 'a t) (x : 'a) : unit =
  StdQueue.add x q

(* Traversal *)
let iter (f : 'a -> unit) (q : 'a t) : unit =
  StdQueue.iter f q

let fold_left (f : 'b -> 'a -> 'b) (init : 'b) (q : 'a t) : 'b =
  StdQueue.fold f init q

let to_seq (q : 'a t) : 'a Seq.t =
  StdQueue.to_seq q

let to_list (q : 'a t) : 'a list =
  q |> to_seq |> List.of_seq