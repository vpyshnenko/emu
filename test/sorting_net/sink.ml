(* sink.ml - consume all routers out streams *)

open Emu
open Emu.Instructions

module IntMap = Map.Make(Int)


(* Define input and output port structures *)
type sink_input = {
  data : int;     (* Port to receive all routers out stream *)
}

type sink_output = {
  out : int;     (* forward all input data to out *)
}

type t = {
  node: Node.t;
  id : int;
  input : sink_input;
  output : sink_output;
}

let input = { data = 0 }
let output = { out = 0 }
let out_ports = [0]

let data_handler = [ EmitTo output.out ]

let handlers = IntMap.empty
  |> IntMap.add input.data data_handler

let vm = Vm.create ~stack_capacity:30 ~max_steps:1000 ~mem_size:0
let initial_state = []  (* Sink is stateless *)

let make ~id : t =
  let node = Node.create 
      ~id 
      ~state:initial_state 
      ~vm 
      ~handlers
      ~out_ports
      ()
  in
  { id; node; input; output }