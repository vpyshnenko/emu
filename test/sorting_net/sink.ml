(* sink.ml - consume all routers out streams *)

open Emu
open Emu.Instructions

module IntMap = Map.Make(Int)


(* Define input and output port structures *)
type sink_input = {
  data : int;     (* Port to receive all routers out stream *)
  overflow: int;
}

type sink_output = {
  out : int;     (* forward all input data to out *)
  overflow: int
}

type t = {
  node: Node.t;
  id : int;
  input : sink_input;
  output : sink_output;
}

let input = { data = 0; overflow = 1; }
let output = { out = 0 ; overflow = 1;}
let out_ports = [0; 1]

let data_handler = [ EmitTo output.out ]
let overflow_handler = [ EmitTo output.overflow ]

let handlers = IntMap.empty
  |> IntMap.add input.data data_handler
  |> IntMap.add input.overflow overflow_handler

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