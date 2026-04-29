(* ext.ml - External events node for digital locker tests *)

open Emu
module IntMap = Map.Make(Int)

(* Define input and output port structures *)

type ext_output = {
  data : int;           (* Emit data stream to sort *)
  reset : int;        (* reset all routers *)
}

type t = {
  node: Node.t;
  id : int;
  output : ext_output;
}

let output = { data = 0; reset = 1 }

let out_ports = [output.data; output.reset]

let make ~id : t =
  let node = Node.create 
    ~id 
    ~state:[] 
    ~vm:Vm.empty
    ~handlers:IntMap.empty
    ~out_ports
    ()
  in
  {
    id;
    node;
    output;
  }

