(* ------------------------------------------------------------ *)
(* Node Builder                                                 *)
(* ------------------------------------------------------------ *)
module IntMap = Map.Make(Int)

module NodeBuilder = struct
  (* Global node ID counter *)
  let next_node_id = ref 1   (* 0 is reserved for god node *)

  type t = {
    add_handler  : Instructions.instr list -> int;
    add_out_port : unit -> int;
    finalize     : unit -> Node.t;
  }

  let create ~state ~(vm : Vm.t) =
    (* Builder state captured in closures *)
    let next_in_port  = ref 1 in
    let next_out_port = ref 1 in
    let handlers      = ref [] in
    let out_ports     = ref [] in

    let add_handler code =
      let p = !next_in_port in
      incr next_in_port;
      handlers := (p, code) :: !handlers;
      p
    in

    let add_out_port () =
      let id = !next_out_port in
      incr next_out_port;
      out_ports := !out_ports @ [id];
      id
    in

    let finalize () =
      let id = !next_node_id in
      incr next_node_id;

      let handlers_map =
        List.fold_left
          (fun acc (p, code) -> IntMap.add p code acc)
          IntMap.empty
          !handlers
      in

      Node.create
        ~id
        ~state
        ~vm
        ~handlers:handlers_map
        ~out_ports:!out_ports
        ()
    in

    { add_handler; add_out_port; finalize }
end


(* ------------------------------------------------------------ *)
(* Net Builder (mutates immediately, no lists, no folding)      *)
(* ------------------------------------------------------------ *)

module NetBuilder = struct
  type t = {
    add_node : Node.t -> int;
    connect  : src:int -> out_port:int -> dst:int -> in_port:int -> unit;
    finalize : unit -> Net.t;
  }

  let create () =
    let net = ref (Net.create ()) in

    let add_node node =
      net := Net.add_node node !net;
      node.Node.id
    in

    let connect ~src ~out_port ~dst ~in_port =
      net :=
        Net.connect
          { from = (src, out_port); to_ = (dst, in_port) }
          !net
    in

    let finalize () =
      !net
    in

    (* DSL operator *)
    let ( --> ) (src, out_port) (dst, in_port) =
      connect ~src ~out_port ~dst ~in_port
    in

    ({ add_node; connect; finalize }, ( --> ))
end



(* ------------------------------------------------------------ *)
(* Public API                                                   *)
(* ------------------------------------------------------------ *)

module Node = NodeBuilder
module Net  = NetBuilder
