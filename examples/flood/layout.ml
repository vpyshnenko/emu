(* Generated automatically by gen_layout.ml. Do not edit manually! *)

type mem = {
  count : int;
}

let mem = {
  count = 0;
}

let to_state (mem_values : mem) : int list =
  [ mem_values.count ]

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
  rx : int;
}

let input = {
  rx = 0;
}

let make_handlers ~rx =
  Emu.Node.IntMap.empty
  |> Emu.Node.IntMap.add input.rx rx

let string_of_input_port = function
  | 0 -> "rx"
  | idx -> "port_" ^ string_of_int idx

let string_of_output_port = function
  | 0 -> "tx"
  | 1 -> "data"
  | idx -> "port_" ^ string_of_int idx

let mem_names = [ "count" ]
