(* net.ml *)

module IntMap = Map.Make(Int)
module IntPairMap = Map.Make(struct
  type t = int * int
  let compare = compare
end)

type t = {
  nodes    : Node.t IntMap.t;                 (* node_id → node *)
  routing  : (int * int) list IntPairMap.t;   (* (src_id, out_port_id) → (dst_id, in_port) list *)
}

(* ------------------------------------------------------------ *)
(* Network creation                                             *)
(* ------------------------------------------------------------ *)

let create () =
  (* God node: forwards any incoming payload to its only out-port *)
  let god =
    Node.create
      ~id:0
      ~state:[]
      ~vm:Vm.empty
      ~handlers:IntMap.empty
      ~out_ports:[0]     (* one outgoing port with actual id = 0 *)
      ()
  in

  {
    nodes   = IntMap.singleton 0 god;
    routing = IntPairMap.empty;
  }

(* ------------------------------------------------------------ *)
(* Node lookup                                                  *)
(* ------------------------------------------------------------ *)

let get_node net id =
  match IntMap.find_opt id net.nodes with
  | Some n -> n
  | None ->
      failwith (Printf.sprintf "net: node %d not found" id)

(* ------------------------------------------------------------ *)
(* Add a node                                                   *)
(* ------------------------------------------------------------ *)

let add_node node net =
  let id = node.Node.id in
  if IntMap.mem id net.nodes then
    failwith (Printf.sprintf "net: node id %d already exists" id);

  let nodes = IntMap.add id node net.nodes in
  { net with nodes }

(* ------------------------------------------------------------ *)
(* Connect nodes                                                *)
(* ------------------------------------------------------------ *)

type connection = {
  from : int * int;   (* src_id, out_port_id *)
  to_  : int * int;   (* dst_id, in_port_index *)
}

let connect { from = (src_id, out_p); to_ = (dst_id, in_p) } net =
  let src_node = get_node net src_id in
  let dst_node = get_node net dst_id in

  if not (Node.has_out_port src_node out_p) then
    failwith (Printf.sprintf "net: node %d has no outgoing port %d" src_id out_p);

  if not (Node.has_in_port dst_node in_p) then
    failwith (Printf.sprintf "net: node %d has no incoming port %d" dst_id in_p);

  let old =
    match IntPairMap.find_opt (src_id, out_p) net.routing with
    | Some lst -> lst
    | None -> []
  in

  let routing =
    IntPairMap.add (src_id, out_p) ((dst_id, in_p) :: old) net.routing
  in

  { net with routing }

(* ------------------------------------------------------------ *)
(* Deliver an event to a single destination node                *)
(* ------------------------------------------------------------ *)

let deliver net dst_id in_port payload =
  let dst_node = get_node net dst_id in

  if dst_node.halted then
    (net, [])
  else begin
    let updated_node, outs =
      Node.handle_event dst_node ~port:in_port ~payload
    in

    let nodes = IntMap.add dst_id updated_node net.nodes in
    let net = { net with nodes } in

    (* Remove routing entries pointing to halted node *)
    let net =
      if updated_node.halted then
        let routing =
          IntPairMap.fold
            (fun key lst acc ->
               let filtered =
                 List.filter (fun (dst, _) -> dst <> dst_id) lst
               in
               if filtered = [] then acc
               else IntPairMap.add key filtered acc
            )
            net.routing
            IntPairMap.empty
        in
        { net with routing }
      else
        net
    in

    (net, outs)
  end

let subscribers net src out_port =
  match IntPairMap.find_opt (src, out_port) net.routing with
  | Some lst -> lst
  | None -> []
