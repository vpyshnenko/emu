open Emu
open Layout

module IntMap = Map.Make(Int)


type t = {
  mutable next_node_id : int;                         (* ID generator *)
  mutable nodes : unit IntMap.t;
  mutable connections : Emu.Net.connection list;
}

(* Creates a builder starting with autoincremented Node IDs from 0 *)
let create () = {
  next_node_id = 0;
  nodes = IntMap.empty;
  connections = [];
}

let state = [0; -1; max_int; 0; -1; -1]
let vm = Emu.Vm.create ~stack_capacity:16 ~max_steps:200 ~mem_size:(List.length state)

let handlers = Handlers.handlers

(* Adds a node, autoincrementing its ID and pre-registering Port 0 *)
let add_node t =
  let id = t.next_node_id in
  t.next_node_id <- id + 1;  (* Increment for the next node call *)
  t.nodes <- IntMap.add id () t.nodes;
  id                          (* Return the autoincremented ID *)

(* Connects two nodes symmetrically using a shared STP handler *)
let add_connection t idA idB out_port in_port  =
  let conn_ab = { Emu.Net.from = (idA, out_port); to_ = (idB, in_port) } in
  let conn_ba = { Emu.Net.from = (idB, out_port); to_ = (idA, in_port) } in
  t.connections <- conn_ab::conn_ba::t.connections
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
  add_connection t idA idB output.stp input.stp;
  add_connection t idA idB output.count_init input.count_init;
  add_connection t idA idB output.count input.count

(* Compiles everything into a finalized Net.t instance *)
let finalize t =
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
    Emu.Net.add_node node acc_net
  ) t.nodes (Emu.Net.create ()) in

  (* 2. Apply all connections to routing tables *)
  List.fold_left (fun acc_net connection ->
    acc_net 
    |> Emu.Net.connect connection 
  ) net t.connections


let attach_ext net root_id =  
  let ext_node = Node.create 
    ~id: (-1) 
    ~state:[] 
    ~vm:Vm.empty
    ~handlers:Node.IntMap.empty
    ~out_ports: [output.stp; output.count_init]
    ()
  in
  
  Emu.Net.add_node ext_node net
    |> Emu.Net.connect { from = (ext_node.id, output.stp); to_ = (root_id, input.stp_init) }
    |> Emu.Net.connect { from = (ext_node.id, output.count_init); to_ = (root_id, input.count_init) }
  
  
  
  
  
