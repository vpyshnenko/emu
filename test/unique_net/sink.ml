(* sink.ml - consume all routers out streams *)

open Emu
open Emu.Instructions

module IntMap = Map.Make(Int)

type sink_mem = {
  count: int;
}

(* Define input and output port structures *)
type sink_input = {
  data : int;     (* Port to receive all routers out stream *)
  overflow: int;
  reset : int;
  
}

type sink_output = {
  out : int;     (* forward all input data to out *)
  overflow: int;
  saturated: int;
}

type t = {
  node: Node.t;
  id : int;
  input : sink_input;
  output : sink_output;
}

let mem = { count = 0 }

let input = { data = 0; overflow = 1; reset = 2 }
let output = { out = 0 ; overflow = 1; saturated = 2}
let out_ports = [0; 1; 2]

let data_handler = [
  EmitTo output.out;
  Load mem.count;
  PushConst 1; Sub; Store mem.count;
  Eq 0;
  BranchOf [|
	[ PushConst 1; PopA; EmitTo output.saturated ]
  |];

]
  
let overflow_handler = [ EmitTo output.overflow ]

let reset_handler size = [
  PushConst size; Store mem.count;
  LogStack;
]

let handlers = IntMap.empty
  |> IntMap.add input.data data_handler
  |> IntMap.add input.overflow overflow_handler

let vm = Vm.create ~stack_capacity:30 ~max_steps:1000 ~mem_size:1
let initial_state = []  (* Sink is stateless *)

let make ~l ~id : t =
  let size = (1 lsl l) - 1 in (* 2^l -1 *)
  let handlers = IntMap.add input.reset (reset_handler size) handlers in
  let node = Node.create 
      ~id 
      ~state:[size]
      ~vm 
      ~handlers
      ~out_ports
      ()
  in
  { id; node; input; output }