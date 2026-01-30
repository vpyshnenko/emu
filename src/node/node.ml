(* node.ml *)

open Instructions

module IntMap = Map.Make(Int)

type t = {
  state          : State.t;
  vm             : Vm.t;

  (* incoming port → handler code *)
  handlers       : instr list IntMap.t;

  (* outgoing ports: list of actual port IDs *)
  out_ports      : int list;

  (* next actual port ID to assign *)
  next_port_id   : int;

  (* next free incoming port index *)
  next_in_port   : int;

  (* node-level halting flag *)
  halted         : bool;
}

(* ------------------------------------------------------------ *)
(* Node creation                                                *)
(* ------------------------------------------------------------ *)

let empty = {
  vm = Vm.empty;
  state = [];
  handlers = IntMap.empty;
  out_ports = [];
  next_port_id = 0;
  next_in_port = 0;
  halted = false;
}

let create ?state ~vm () =
  {
    state          = Option.value ~default:[] state;
    vm;
    handlers       = IntMap.empty;
    out_ports      = [];
    next_port_id   = 0;
    next_in_port   = 0;
    halted         = false;
  }

(* ------------------------------------------------------------ *)
(* Outgoing ports                                               *)
(* ------------------------------------------------------------ *)

(* Adds a new outgoing port, returns symbolic index *)
let add_out_port node =
  let actual_id = node.next_port_id in
  let node' =
    { node with
        out_ports = node.out_ports @ [actual_id];
        next_port_id = actual_id + 1;
    }
  in
  (node', actual_id)


let has_out_port node idx =
  idx >= 0 && idx < List.length node.out_ports

(* ------------------------------------------------------------ *)
(* Handlers and incoming ports                                  *)
(* ------------------------------------------------------------ *)

let add_handler code node =
  let port = node.next_in_port in
  let handlers = IntMap.add port code node.handlers in
  let node' =
    { node with
        handlers;
        next_in_port = port + 1;
    }
  in
  (node', port)

let has_in_port node p =
  IntMap.mem p node.handlers

(* ------------------------------------------------------------ *)
(* Event dispatch                                               *)
(* ------------------------------------------------------------ *)

let handle_event node ~port ~payload =
  if node.halted then
    (node, [])
  else
    (* 1. Lookup handler code *)
    let code =
      match IntMap.find_opt port node.handlers with
      | Some c -> c
      | None ->
          failwith
            (Printf.sprintf
               "node: no handler mapped to incoming port %d" port)
    in

    (* 2. Execute handler *)
    let out_port_count = List.length node.out_ports in
    let new_state, outs, halted =
      Vm.exec_program
        node.vm
        node.state
        code
        payload
        ~out_port_count
    in

    (* 3. Map symbolic indices → actual port IDs *)
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
