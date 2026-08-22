open Emu
open Layout

module IntMap = Map.Make(Int)


type t = {
  mutable next_node_id : int;                         (* ID generator *)
  mutable nodes : unit IntMap.t;
  mutable connections : (
    Net.connection *
	Net.connection *
	Net.connection *
	Net.connection *
	Net.connection *
	Net.connection
  ) list;
}

(* Creates a builder starting with autoincremented Node IDs from 0 *)
let create () = {
  next_node_id = 0;
  nodes = IntMap.empty;
  connections = [];
}

let vm = Emu.Vm.create ~stack_capacity:16 ~max_steps:200 ~mem_size:4
let state = [-1; max_int; 0; -1]

let handlers = Handlers.handlers

(* Adds a node, autoincrementing its ID and pre-registering Port 0 *)
let add_node t =
  let id = t.next_node_id in
  t.next_node_id <- id + 1;  (* Increment for the next node call *)
  t.nodes <- IntMap.add id () t.nodes;
  id                          (* Return the autoincremented ID *)

(* Connects two nodes symmetrically using a shared STP handler *)
let connect t idA idB =
  let _ = match IntMap.find_opt idA t.nodes with
    | Some n -> n
    | None -> failwith (Printf.sprintf "NetBuilder: node %d not found" idA)
  in
  let _ = match IntMap.find_opt idB t.nodes with
    | Some n -> n
    | None -> failwith (Printf.sprintf "NetBuilder: node %d not found" idB)
  in
  
  (* Setup physical network connections *)
  let stp_ab = { Net.from = (idA, output.stp); to_ = (idB, input.stp) } in
  let stp_ba = { Net.from = (idB, output.stp); to_ = (idA, input.stp) } in
  let count_init_ab = { Net.from = (idA, output.count_init); to_ = (idB, input.count_init) } in
  let count_init_ba = { Net.from = (idB, output.count_init); to_ = (idA, input.count_init) } in
  let count_ab = { Net.from = (idA, output.count); to_ = (idB, input.count) } in
  let count_ba = { Net.from = (idB, output.count); to_ = (idA, input.count) } in
  t.connections <- (stp_ab, stp_ba, count_init_ab, count_init_ba, count_ab, count_ba) :: t.connections

(* Compiles everything into a finalized Net.t instance *)
let finalize t root_id =
  (* 1. Instantiate and add all nodes to the network *)
  let net = IntMap.fold (fun id _val acc_net ->
    let node = Node.create 
      ~id 
      ~state
      ~vm
      ~handlers
      ~out_ports: Layout.out_ports
      () 
    in
    Net.add_node node acc_net
  ) t.nodes (Net.create ()) in

  (* 2. Apply all connections to routing tables *)
  let net = List.fold_left (fun acc_net (stp_ab, stp_ba, count_init_ab, count_init_ba, count_ab, count_ba) ->
    acc_net 
    |> Net.connect stp_ab 
    |> Net.connect stp_ba
    |> Net.connect count_init_ab
    |> Net.connect count_init_ba
    |> Net.connect count_ab
    |> Net.connect count_ba
  ) net t.connections in
  
  let ext_node = Node.create 
    ~id: (-1) 
    ~state:[] 
    ~vm:Vm.empty
    ~handlers:Node.IntMap.empty
    ~out_ports: [0; 1]
    ()
  in
  
  Net.add_node ext_node net
    |> Net.connect { from = (ext_node.id, 0); to_ = (root_id, input.stp_init) }
    |> Net.connect { from = (ext_node.id, 1); to_ = (root_id, input.count_init) }
  
  
  
  
  
