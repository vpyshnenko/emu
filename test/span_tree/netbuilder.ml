open Emu

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

let vm = Emu.Vm.create ~stack_capacity:16 ~max_steps:200 ~mem_size:3
let state = [-1; max_int; 0]

let stp_init = 0
let stp_in = 1
let count_init = 2
let count_in = 3

let stp_out = 0
let count_init_out = 1
let count_out = 2


let handlers =
	Node.IntMap.empty
	|> Node.IntMap.add stp_init Handlers.stp_init
	|> Node.IntMap.add stp_in Handlers.stp
	|> Node.IntMap.add count_init Handlers.count_init
	|> Node.IntMap.add count_in Handlers.count_in

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
  let stp_ab = { Net.from = (idA, stp_out); to_ = (idB, stp_in) } in
  let stp_ba = { Net.from = (idB, stp_out); to_ = (idA, stp_in) } in
  let count_init_ab = { Net.from = (idA, count_init_out); to_ = (idB, count_init) } in
  let count_init_ba = { Net.from = (idB, count_init_out); to_ = (idA, count_init) } in
  let count_ab = { Net.from = (idA, count_out); to_ = (idB, count_in) } in
  let count_ba = { Net.from = (idB, count_out); to_ = (idA, count_in) } in
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
      ~out_ports:[stp_out; count_init_out; count_out;]
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
    |> Net.connect { from = (ext_node.id, 0); to_ = (root_id, stp_init) }
    |> Net.connect { from = (ext_node.id, 1); to_ = (root_id, count_init) }
  
  
  
  
  
