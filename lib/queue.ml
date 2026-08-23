(* queue.ml *)

  type 'a t = {
    front : 'a list;   (* dequeue from here *)
    back  : 'a list;   (* enqueue here, reversed *)
  }

  let empty = { front = []; back = [] }

  let is_empty q =
    match q.front, q.back with
    | [], [] -> true
    | _ -> false

  let enqueue x q =
    { q with back = x :: q.back }

  let normalize q =
    match q.front with
    | [] ->
        begin match List.rev q.back with
        | [] -> q
        | front' -> { front = front'; back = [] }
        end
    | _ -> q

  let dequeue q =
    match q.front with
    | x :: front' ->
        Some (x, { q with front = front' })
    | [] ->
        begin match List.rev q.back with
        | [] -> None
        | x :: front' ->
            Some (x, { front = front'; back = [] })
        end

