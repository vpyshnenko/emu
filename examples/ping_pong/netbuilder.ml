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

let state = Layout.to_state {parent_id = (-1); distance = max_int; seq_id = 0; ping_session_id = 0;}
let vm = Emu.Vm.create ~stack_capacity:16 ~max_steps:200 ~mem_size:(List.length state)

let handlers = Handlers.handlers
(* let handlers = Handlers_flood.handlers *)

(* Adds a node, autoincrementing its ID and pre-registering Port 0 *)
let add_node t =
  let id = t.next_node_id in
  t.next_node_id <- id + 1;  (* Increment for the next node call *)
  t.nodes <- IntMap.add id () t.nodes;
  id                          (* Return the autoincremented ID *)

let add_ping_pong t idA =
  let  conn_ping = { Emu.Net.from = (idA, output.ping); to_ = (idA, input.send) } in
  let  conn_pong = { Emu.Net.from = (idA, output.pong); to_ = (idA, input.send) } in
  let  conn_data = { Emu.Net.from = (idA, output.data); to_ = (idA, input.pong) } in
  t.connections <- conn_ping::conn_pong::conn_data::t.connections
  
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
  add_connection t idA idB output.tx input.rx;
  add_connection t idA idB output.root_tx input.root_rx;
  add_connection t idA idB output.stp input.stp

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
	add_ping_pong t id;
    Emu.Net.add_node node acc_net
  ) t.nodes (Emu.Net.create ()) in

  (* 2. Apply all connections to routing tables *)
  List.fold_left (fun acc_net connection ->
    acc_net 
    |> Emu.Net.connect connection 
  ) net t.connections

let ext_id = (-1)
let ext_input_data = 0

let ext_stp_id = (-2)

let ext_ping_id = (-3)
let ext_input_ping_ok = 0

let attach_ext (net : Emu.Net.t) =
  (* 1. Gather all active node IDs from the network *)
  let node_ids = IntMap.bindings net.nodes |> List.map (fun (id, _) -> id) in
  
  let ext_node = Node.create 
    ~id:ext_id 
    ~state:[] 
    ~vm:Vm.empty
  (* Only ONE empty handler registered on port 0 for ALL incoming feedback *)
    ~handlers:(Node.IntMap.singleton ext_input_data [])
    (* ~handlers:Node.IntMap.empty *)
    ~out_ports:node_ids 
    ()
  in

  let ext_node_stp = Node.create 
    ~id:ext_stp_id
    ~state:[] 
    ~vm: Vm.empty
    ~handlers:Node.IntMap.empty
    ~out_ports:node_ids 
    ()
  in
  
  let ext_ping_node = Node.create 
    ~id:ext_ping_id 
    ~state:[] 
    ~vm:Vm.empty
  (* Only ONE empty handler registered on port 0 for ALL incoming feedback *)
    ~handlers:(Node.IntMap.singleton ext_input_ping_ok [])
    (* ~handlers:Node.IntMap.empty *)
    ~out_ports:node_ids 
    ()
  in  
  
  net
  (* add ext_node *)
  |> Emu.Net.add_node ext_node
  (* 4. Symmetrically wire the control plane and the shared feedback plane *)
  |> IntMap.fold (fun node_id _node acc_net ->
    acc_net
    (* CONTROL LINE: ext_node (dedicated port node_id) -> node (input.send) *)
    |> Emu.Net.connect { 
         from = (ext_id, node_id); 
         to_ = (node_id, input.send) 
       }
    (* FEEDBACK LINE: node (output.data) -> ext_node (shared ext_input_data 0) *)
    (* Connects send triggers 1-to-1 AND binds all node 'data' outports back to ext_node *)
    |> Emu.Net.connect { 
         from = (node_id, output.data); 
         to_ = (ext_id, ext_input_data) 
       }
  ) net.nodes
  
  (* add ext_node_stp *)
  |> Emu.Net.add_node ext_node_stp
  |> IntMap.fold (fun node_id _node acc_net ->
    acc_net
    (* CONTROL LINE: ext_node (dedicated port node_id) -> node (input.send) *)
    |> Emu.Net.connect { 
         from = (ext_stp_id, node_id); 
         to_ = (node_id, input.stp_init) 
       }
  ) net.nodes
  
  (* add ext_ping_node *)
  |> Emu.Net.add_node ext_ping_node
  (* 4. Symmetrically wire the control plane and the shared feedback plane *)
  |> IntMap.fold (fun node_id _node acc_net ->
    acc_net
    |> Emu.Net.connect { 
         from = (ext_ping_id, node_id); 
         to_ = (node_id, input.ping) 
       }
    |> Emu.Net.connect { 
         from = (node_id, output.ping_ok); 
         to_ = (ext_ping_id, ext_input_ping_ok) 
       }
  ) net.nodes
  
  
  
  
