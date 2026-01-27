(* node.ml *)

open Instructions

module StringMap = Map.Make(String)
module IntMap    = Map.Make(Int)

type t = {
  state          : State.t;
  vm             : Vm.t;

  (* incoming port → handler code *)
  handlers       : instr list IntMap.t;

  (* outgoing stream alias → port number *)
  outgoing_ports : int StringMap.t;

  (* next free incoming port *)
  next_in_port   : int;

  (* next free outgoing port *)
  next_out_port  : int;

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
  outgoing_ports = StringMap.empty;
  next_in_port   = 0;
  next_out_port  = 0;
  halted         = false;
}

let create ?state ~vm () =
  {
    state          = Option.value ~default:[] state;
    vm;
    handlers       = IntMap.empty;
    outgoing_ports = StringMap.empty;
    next_in_port   = 0;
    next_out_port  = 0;
    halted         = false;
  }

(* ------------------------------------------------------------ *)
(* Outgoing streams                                             *)
(* ------------------------------------------------------------ *)

let add_out_port alias node =
  if StringMap.mem alias node.outgoing_ports then
    failwith
      (Printf.sprintf "node: outgoing stream '%s' already exists" alias);

  let port = node.next_out_port in
  let outgoing_ports =
    StringMap.add alias port node.outgoing_ports
  in
  let node' =
    { node with
        outgoing_ports;
        next_out_port = port + 1;
    }
  in
  (node', port)
  
let has_out_port node p =
  (* outgoing_ports : alias → port_id *)
  StringMap.exists (fun _alias port_id -> port_id = p) node.outgoing_ports

(* ------------------------------------------------------------ *)
(* Handlers and incoming ports                                  *)
(* ------------------------------------------------------------ *)

let add_handler code node =
  let port = node.next_in_port in

  let handlers =
    IntMap.add port code node.handlers
  in

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
    (* 1. Lookup handler code directly by numeric port *)
    let code =
      match IntMap.find_opt port node.handlers with
      | Some c -> c
      | None ->
          failwith
            (Printf.sprintf
               "node: no handler mapped to incoming port %d" port)
    in

    (* 2. Execute handler *)
    let new_state, outs, halted =
      Vm.exec_program node.vm node.state code payload
    in

    (* 3. Translate outgoing aliases → numeric port IDs *)
    let translated_outs =
      List.map
        (fun (alias, v) ->
           match StringMap.find_opt alias node.outgoing_ports with
           | Some out_port -> (out_port, v)
           | None ->
               failwith
                 (Printf.sprintf
                    "node: handler emitted to unknown stream alias '%s'" alias)
        )
        outs
    in

    ({ node with state = new_state; halted }, translated_outs)
