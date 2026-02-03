(* node.ml *)

open Instructions

module IntMap = Map.Make(Int)

type t = {
  id        : int;                     (* stable node identity *)
  state     : State.t;                 (* immutable persistent user state *)
  vm        : Vm.t;

  handlers  : instr list IntMap.t;     (* incoming port index → handler code *)
  out_ports : int list;                (* outgoing ports: actual IDs *)

  halted    : bool;
}

(* ------------------------------------------------------------ *)
(* Node creation                                                *)
(* ------------------------------------------------------------ *)

let empty = {
  id = -1;
  vm = Vm.empty;
  state = [];
  handlers = IntMap.empty;
  out_ports = [];
  halted = false;
}

let create ~id ~state ~vm ~handlers ~out_ports () =
  {
    id;
    state;
    vm;
    handlers;
    out_ports;
    halted = false;
  }

(* ------------------------------------------------------------ *)
(* Builder-supplied port registration                           *)
(* ------------------------------------------------------------ *)

let add_out_port ~actual_id node =
  { node with out_ports = node.out_ports @ [actual_id] }

let add_handler ~in_port ~code node =
  { node with handlers = IntMap.add in_port code node.handlers }

(* Now we check by *value*, not by index *)
let has_out_port node port_id =
  List.exists (fun id -> id = port_id) node.out_ports

let has_in_port node p =
  IntMap.mem p node.handlers

(* ------------------------------------------------------------ *)
(* Event dispatch                                               *)
(* ------------------------------------------------------------ *)

let handle_event node ~port ~payload =
  if node.halted then
    (node, [])
  else
    let code =
      match IntMap.find_opt port node.handlers with
      | Some c -> c
      | None ->
          failwith
            (Printf.sprintf
               "node: no handler mapped to incoming port %d" port)
    in

    let meta_info =
      [
        node.id;
        List.length node.out_ports;
        IntMap.cardinal node.handlers;
      ]
    in

    let out_port_count = List.length node.out_ports in
    let new_state, outs, halted =
      Vm.exec_program
	    node.vm
        node.state
        meta_info
        code
        payload
        out_port_count
    in

    let out_ports_array = Array.of_list node.out_ports in

    let translated_outs =
      List.map
        (fun (sym_idx, v) ->
           if sym_idx < 0 || sym_idx >= Array.length out_ports_array then
             failwith
               (Printf.sprintf
                  "node: handler emitted invalid port index %d" sym_idx);
           let actual_id = out_ports_array.(sym_idx) in
           (actual_id, v)
        )
        outs
    in

    ({ node with state = new_state; halted }, translated_outs)
