(* Generated automatically by gen_layout.ml. Do not edit manually! *)

type mem = {
  parent_node_id : int;
  distance : int;
  count : int;
  max_node_id : int;
  eccentricity : int;
}

let mem = {
  parent_node_id = 0;
  distance = 1;
  count = 2;
  max_node_id = 3;
  eccentricity = 4;
}

type output = {
  stp : int;
  count_init : int;
  count : int;
}

let output = {
  stp = 0;
  count_init = 1;
  count = 2;
}

let out_ports = [ output.stp; output.count_init; output.count ]

type input = {
  stp_init : int;
  stp : int;
  count_init : int;
  count : int;
}

let input = {
  stp_init = 0;
  stp = 1;
  count_init = 2;
  count = 3;
}

let make_handlers ~stp_init ~stp ~count_init ~count =
  Emu.Node.IntMap.empty
  |> Emu.Node.IntMap.add input.stp_init stp_init
  |> Emu.Node.IntMap.add input.stp stp
  |> Emu.Node.IntMap.add input.count_init count_init
  |> Emu.Node.IntMap.add input.count count

let string_of_input_port = function
  | 0 -> "stp_init"
  | 1 -> "stp"
  | 2 -> "count_init"
  | 3 -> "count"
  | idx -> "port_" ^ string_of_int idx

let string_of_output_port = function
  | 0 -> "stp"
  | 1 -> "count_init"
  | 2 -> "count"
  | idx -> "port_" ^ string_of_int idx

let mem_names = [ "parent_node_id"; "distance"; "count"; "max_node_id"; "eccentricity" ]
