(* dlist.ml *)

type 'a t = 'a list -> 'a list

(* ------------------------------------------------------------ *)
(* Constructors                                                 *)
(* ------------------------------------------------------------ *)

let empty : 'a t =
  fun tail -> tail

let singleton (x : 'a) : 'a t =
  fun tail -> x :: tail

let of_list (lst : 'a list) : 'a t =
  fun tail ->
    (* fold_right avoids allocating an intermediate list *)
    List.fold_right (fun x acc -> x :: acc) lst tail

(* ------------------------------------------------------------ *)
(* Core operations                                              *)
(* ------------------------------------------------------------ *)

let cons (x : 'a) (d : 'a t) : 'a t =
  fun tail -> x :: d tail

let snoc (x : 'a) (d : 'a t): 'a t =
  fun tail -> d (x :: tail)

let append (d1 : 'a t) (d2 : 'a t) : 'a t =
  fun tail -> d1 (d2 tail)

(* ------------------------------------------------------------ *)
(* Materialization                                              *)
(* ------------------------------------------------------------ *)

let to_list (d : 'a t) : 'a list =
  d []

(* ------------------------------------------------------------ *)
(* Higher-order operations                                      *)
(* ------------------------------------------------------------ *)

let map (f : 'a -> 'b) (d : 'a t) : 'b t =
  fun tail ->
    (* One traversal: materialize + map + rebuild *)
    List.fold_right (fun x acc -> f x :: acc) (d []) tail

let fold_left (f : 'b -> 'a -> 'b) (acc : 'b) (d : 'a t) : 'b =
  (* One traversal: materialize + fold *)
  List.fold_left f acc (d [])

let fold_right (f : 'a -> 'b -> 'b) (d : 'a t) (acc : 'b) : 'b =
  (* fold_right inherently requires full list first *)
  List.fold_right f (d []) acc
