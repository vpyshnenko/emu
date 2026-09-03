open Netbuilder


(* Generates a symmetric linear network of size n *)
let make_linear_net n =
  if n <= 0 then failwith "Cannot create a linear network with 0 or fewer nodes";
  
  let builder = create () in

  (* 1. Dynamically instantiate n nodes and capture their generated IDs *)
  let nodes = List.init n (fun _ -> add_node builder) in

  (* 2. Recursively connect adjacent pairs in the list (u <-> v) *)
  let rec connect_adjacent = function
    | [] | [_] -> () (* 0 or 1 nodes left -> nothing to connect *)
    | u :: v :: rest ->
        connect builder u v;
        connect_adjacent (v :: rest) (* Slide the window to connect (v <-> next) *)
  in
  connect_adjacent nodes;

  (* 3. Compile and return the finalized network *)
  finalize builder
  

let make_ring_net n =
  if n < 3 then 
    failwith "Cannot create a ring network with fewer than 3 nodes";
  let builder = create () in
  
  (* 1. Dynamically instantiate n nodes and capture their generated IDs *)
  let nodes = List.init n (fun _ -> add_node builder) in
  
  (* 2. Recursively connect nodes in a loop: u_i <-> u_{i+1}, and u_{n-1} <-> u_0 *)
  let rec connect_ring = function
    | [] | [_] -> ()
    | [u; v] -> 
        connect builder u v;
        let head = List.hd nodes in
        connect builder v head (* Close the loop back to the first node *)
    | u :: v :: rest ->
        connect builder u v;
        connect_ring (v :: rest) (* Slide the window *)
  in
  connect_ring nodes;
  
  (* 3. Compile and return the finalized network *)
  finalize builder


let make_cycle_net () =
  let builder = create () in

  let n0 = add_node builder in
  let n1 = add_node builder in
  let n2 = add_node builder in
  let n3 = add_node builder in
  let n4 = add_node builder in
  let n5 = add_node builder in
  let n6 = add_node builder in
  let n7 = add_node builder in

  connect builder n0 n1;
  connect builder n1 n2;
  connect builder n2 n3;
  connect builder n0 n3;
  connect builder n4 n5;
  connect builder n5 n6;
  connect builder n6 n7;
  connect builder n4 n7;
  connect builder n0 n4;
  connect builder n1 n5;
  connect builder n2 n6;
  connect builder n3 n7;
  
  finalize builder
  
let cycle_net = make_cycle_net ()
