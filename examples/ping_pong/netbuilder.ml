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

let state = [0]
let vm = Emu.Vm.create ~stack_capacity:16 ~max_steps:200 ~mem_size:(List.length state)

(* let handlers = Handlers.handlers *)
let handlers = Handlers_flood.handlers

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
  add_connection t idA idB output.tx input.rx

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

let ext_node_id = (-1)

(* Connects send triggers 1-to-1 AND binds all node 'data' outports back to ext_node *)
let ext_input_data = 0

let attach_ext (net : Emu.Net.t) =
  (* 1. Gather all active node IDs from the network *)
  let node_ids = IntMap.bindings net.nodes |> List.map (fun (id, _) -> id) in
  
  (* 2. Only ONE empty handler registered on port 0 for ALL incoming feedback *)
  let ext_handlers = Emu.Node.IntMap.singleton ext_input_data [] in

  (* 3. Create the ext_node with a single feedback handler *)
  let ext_node = Node.create 
    ~id:ext_node_id 
    ~state:[] 
    ~vm:(Vm.create ~stack_capacity:10 ~max_steps:10 ~mem_size:0)
    ~handlers:ext_handlers 
    ~out_ports:node_ids 
    () 
  in
  let net_with_ext = Emu.Net.add_node ext_node net in
  
  (* 4. Symmetrically wire the control plane and the shared feedback plane *)
  IntMap.fold (fun node_id _node acc_net ->
    acc_net
    (* CONTROL LINE: ext_node (dedicated port node_id) -> node (input.send) *)
    |> Emu.Net.connect { 
         from = (ext_node_id, node_id); 
         to_ = (node_id, input.send) 
       }
    (* FEEDBACK LINE: node (output.data) -> ext_node (shared ext_input_data 0) *)
    |> Emu.Net.connect { 
         from = (node_id, output.data); 
         to_ = (ext_node_id, ext_input_data) 
       }
  ) net.nodes net_with_ext
  
  
  
  
  
