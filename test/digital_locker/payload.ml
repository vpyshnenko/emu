(* payload.ml - Payload node for digital locker *)

open Emu

(* Define input and output port structures *)
type payload_input = {
  set : int;       (* Port to set the payload value *)
  unlock : int;    (* Port to unlock/emit the payload *)
  clear : int;     (* Port to clear the payload *)
}

type payload_output = {
  value : int;     (* Output port for payload value when unlocked *)
}

type payload = {
  node: Node.t;
  id : int;
  input : payload_input;
  output : payload_output;
}

let make_payload () : payload =
  let vm = Vm.create ~stack_capacity:30 ~max_steps:100 ~mem_size:1 in
  let initial_state = [0] in  (* Payload starts as 0 *)
  let b = Builder.Node.create ~state:initial_state ~vm () in
  
  (* INPUT PORTS - in declaration order *)
  let set = b.add_handler [
    PushA;           (* Push payload value from register A *)
    Store 0;         (* Store in state[0] *)
  ] in
  
  let unlock = b.add_handler [
    Load 0;          (* Load stored payload value *)
    PopA;            (* Move to register A *)
    EmitTo 0;        (* Emit to port 0 (value output) *)
  ] in
  
  let clear = b.add_handler [
    PushConst 0;     (* Push 0 *)
    Store 0;         (* Clear state[0] *)
  ] in
  
  (* OUTPUT PORTS - in declaration order *)
  let value = b.add_out_port () in  (* port 0 *)
  
  (* Build the record with all captured port IDs *)
  let input = {
    set;
    unlock;
    clear;
  } in
  
  let output = {
    value;
  } in
  
  let node = b.finalize () in
  
  {
    id = node.id;
    node;
    input;
    output;
  }