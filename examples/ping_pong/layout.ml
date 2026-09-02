(* Generated automatically by gen_layout.ml. Do not edit manually! *)

type mem = {
  parent_id : int;
  seq_id : int;
  distance : int;
}

let mem = {
  parent_id = 0;
  seq_id = 1;
  distance = 2;
}

let to_state (mem_values : mem) : int list =
  [ mem_values.parent_id; mem_values.seq_id; mem_values.distance ]

type output = {
  stp : int;
  root_tx : int;
  tx : int;
  data : int;
  ping : int;
  ping_ok : int;
  pong : int;
}

let output = {
  stp = 0;
  root_tx = 1;
  tx = 2;
  data = 3;
  ping = 4;
  ping_ok = 5;
  pong = 6;
}

let out_ports = [ output.stp; output.root_tx; output.tx; output.data; output.ping; output.ping_ok; output.pong ]

type input = {
  stp_init : int;
  stp : int;
  root_rx : int;
  send : int;
  rx : int;
  ping : int;
  pong : int;
}

let input = {
  stp_init = 0;
  stp = 1;
  root_rx = 2;
  send = 3;
  rx = 4;
  ping = 5;
  pong = 6;
}

let make_handlers ~stp_init ~stp ~root_rx ~send ~rx ~ping ~pong =
  Emu.Node.IntMap.empty
  |> Emu.Node.IntMap.add input.stp_init stp_init
  |> Emu.Node.IntMap.add input.stp stp
  |> Emu.Node.IntMap.add input.root_rx root_rx
  |> Emu.Node.IntMap.add input.send send
  |> Emu.Node.IntMap.add input.rx rx
  |> Emu.Node.IntMap.add input.ping ping
  |> Emu.Node.IntMap.add input.pong pong

let string_of_input_port = function
  | 0 -> "stp_init"
  | 1 -> "stp"
  | 2 -> "root_rx"
  | 3 -> "send"
  | 4 -> "rx"
  | 5 -> "ping"
  | 6 -> "pong"
  | idx -> "port_" ^ string_of_int idx

let string_of_output_port = function
  | 0 -> "stp"
  | 1 -> "root_tx"
  | 2 -> "tx"
  | 3 -> "data"
  | 4 -> "ping"
  | 5 -> "ping_ok"
  | 6 -> "pong"
  | idx -> "port_" ^ string_of_int idx

let mem_names = [ "parent_id"; "seq_id"; "distance" ]
