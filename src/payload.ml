(*=== src/payload.ml ===*)
type t = int list

let empty : t = []

(* Handy formatter for debugging/digests *)
let to_string (p : t) : string =
  "[" ^ (String.concat "; " (List.map string_of_int p)) ^ "]"