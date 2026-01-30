(* ------------------------------------------------------------ *)
(* Node Builder                                                 *)
(* ------------------------------------------------------------ *)

module NodeBuilder = struct
  type t = {
    add_handler  : Instructions.instr list -> int;
    add_out_port : unit -> int;
    finalize     : unit -> Node.t;
  }

  let create ~state ~(vm:Vm.t) =
    (* Ensure state is exactly vm.mem_size long *)
    let padded_state =
      let len = List.length state in
      if len > vm.mem_size then
        failwith "Builder.Node: initial state exceeds VM memory size";
      if len = vm.mem_size then
        state
      else
        (* pad with zeros *)
        state @ (List.init (vm.mem_size - len) (fun _ -> 0))
    in
  
    let current = ref (Node.create ~state:padded_state ~vm ()) in
  
    let add_handler prog =
      let node', port_id = Node.add_handler prog !current in
      current := node';
      port_id
    in
  
    let add_out_port () =
      let node', actual_id = Node.add_out_port !current in
      current := node';
      actual_id
    in
  
    let finalize () =
      !current
    in
  
    { add_handler; add_out_port; finalize }

end


(* ------------------------------------------------------------ *)
(* Net Builder (mutates immediately, no lists, no folding)      *)
(* ------------------------------------------------------------ *)

module NetBuilder = struct
  type t = {
    current : Net.t ref;
    add_node : Node.t -> int;
    connect  : src:int -> out_port:int -> dst:int -> in_port:int -> unit;
    finalize : unit -> Net.t;
  }

  let create () =
    let current = ref (Net.create ()) in

    let add_node node =
      let net', id = Net.add_node node !current in
      current := net';
      id
    in

    let connect ~src ~out_port ~dst ~in_port =
      current :=
        Net.connect
          { from = (src, out_port); to_ = (dst, in_port) }
          !current
    in

    let finalize () =
      !current
    in

    (* Wiring DSL operator *)
    let ( --> ) (src, out_port) (dst, in_port) =
      connect ~src ~out_port ~dst ~in_port
    in

    ({ current; add_node; connect; finalize }, ( --> ))
end


(* ------------------------------------------------------------ *)
(* Public API                                                   *)
(* ------------------------------------------------------------ *)

module Node = NodeBuilder
module Net  = NetBuilder
