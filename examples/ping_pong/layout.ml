(* Generated automatically by gen_layout.ml. Do not edit manually! *)

type mem = {
  status : int;
}

let mem = {
  status = 0;
}

type output = {
  ping : int;
  pong : int;
  ok : int;
}

let output = {
  ping = 0;
  pong = 1;
  ok = 2;
}

let out_ports = [ output.ping; output.pong; output.ok ]

type input = {
  ping_init : int;
  ping : int;
  pong : int;
}

let input = {
  ping_init = 0;
  ping = 1;
  pong = 2;
}

let make_handlers ~ping_init ~ping ~pong =
  Emu.Node.IntMap.empty
  |> Emu.Node.IntMap.add input.ping_init ping_init
  |> Emu.Node.IntMap.add input.ping ping
  |> Emu.Node.IntMap.add input.pong pong

let string_of_input_port = function
  | 0 -> "ping_init"
  | 1 -> "ping"
  | 2 -> "pong"
  | idx -> "port_" ^ string_of_int idx

let string_of_output_port = function
  | 0 -> "ping"
  | 1 -> "pong"
  | 2 -> "ok"
  | idx -> "port_" ^ string_of_int idx

let mem_names = [ "status" ]
