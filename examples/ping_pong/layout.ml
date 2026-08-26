(* Generated automatically by gen_layout.ml. Do not edit manually! *)

type mem = {
  seqId : int;
}

let mem = {
  seqId = 0;
}

type output = {
  tx : int;
  data : int;
}

let output = {
  tx = 0;
  data = 1;
}

let out_ports = [ output.tx; output.data ]

type input = {
  send : int;
  rx : int;
}

let input = {
  send = 0;
  rx = 1;
}

let make_handlers ~send ~rx =
  Emu.Node.IntMap.empty
  |> Emu.Node.IntMap.add input.send send
  |> Emu.Node.IntMap.add input.rx rx

let string_of_input_port = function
  | 0 -> "send"
  | 1 -> "rx"
  | idx -> "port_" ^ string_of_int idx

let string_of_output_port = function
  | 0 -> "tx"
  | 1 -> "data"
  | idx -> "port_" ^ string_of_int idx

let mem_names = [ "seqId" ]
