open Emu

module IntMap = Map.Make(Int)


type t = {
  mutable next_node_id : int;                         (* ID generator *)
  mutable nodes : unit IntMap.t;
  mutable connections : (Net.connection * Net.connection) list;
}

(* Creates a builder starting with autoincremented Node IDs from 0 *)
let create () = {
  next_node_id = 0;
  nodes = IntMap.empty;
  connections = [];
}

let vm = Emu.Vm.create ~stack_capacity:16 ~max_steps:200 ~mem_size:2
let state = [-1; 255;]

let init_in = 0
let stp_in = 1

let stp_out = 0

let handlers =
	Node.IntMap.empty
	|> Node.IntMap.add init_in Handlers.init
	|> Node.IntMap.add stp_in Handlers.stp

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
  let forward = { Net.from = (idA, stp_out); to_ = (idB, stp_in) } in
  let reverse = { Net.from = (idB, stp_out); to_ = (idA, stp_in) } in
  t.connections <- (forward, reverse) :: t.connections

(* Compiles everything into a finalized Net.t instance *)
let finalize t root_id =
  (* 1. Instantiate and add all nodes to the network *)
  let net = IntMap.fold (fun id _val acc_net ->
    let node = Node.create 
      ~id 
      ~state
      ~vm
      ~handlers
      ~out_ports:[stp_out]
      () 
    in
    Net.add_node node acc_net
  ) t.nodes (Net.create ()) in

  (* 2. Apply all connections to routing tables *)
  let net = List.fold_left (fun acc_net (forward, reverse) ->
    acc_net 
    |> Net.connect forward 
    |> Net.connect reverse
  ) net t.connections in
  
  let ext_node = Node.create 
    ~id: (-1) 
    ~state:[] 
    ~vm:Vm.empty
    ~handlers:Node.IntMap.empty
    ~out_ports: [0]
    ()
  in
  
  let net = Net.add_node ext_node net in
  Net.connect { from = (ext_node.id, 0); to_ = (root_id, 0) } net 
  
  
  
  
