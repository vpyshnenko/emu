(* queue.ml *)
type 'a t = {
  front : 'a list;  (* Elements ready to be dequeued *)
  back  : 'a list;  (* Enqueued elements in reverse order *)
  size  : int;      (* Pre-calculated size of the queue for O(1) lookup *)
}

(* Creates an empty queue *)
let empty = { front = []; back = []; size = 0 }

(* Checks if the queue is empty *)
let is_empty q = q.size = 0

(* Returns the current number of elements in the queue in O(1) *)
let length q = q.size

(* Explicit size function for direct size retrieval *)

(* Enqueues an element in O(1) *)
let enqueue x q = 
  { q with back = x :: q.back; size = q.size + 1 }

(* Normalizes the queue to ensure 'front' is not empty if elements exist *)
let normalize q = 
  match q.front with
  | [] -> 
      begin match List.rev q.back with
      | [] -> q
      | front' -> { front = front'; back = []; size = q.size }
      end
  | _ -> q

(* Dequeues an element in amortized O(1) *)
let dequeue q = 
  match q.front with
  | x :: front' -> 
      Some (x, { q with front = front'; size = q.size - 1 })
  | [] -> 
      begin match List.rev q.back with
      | [] -> None
      | x :: front' -> Some (x, { front = front'; back = []; size = q.size - 1 })
      end