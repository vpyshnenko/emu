(* vm.ml *)

open Instructions
open Stack

(* ------------------------------------------------------------ *)
(* VM configuration                                             *)
(* ------------------------------------------------------------ *)

type t = {
  stack_capacity : int;
  max_steps      : int;
}

type control =
  | Continue
  | Halt

let create ~stack_capacity ~max_steps =
  { stack_capacity; max_steps }

let empty = { stack_capacity = 0; max_steps = 0 }

(* ------------------------------------------------------------ *)
(* State <-> Stack conversion                                   *)
(* ------------------------------------------------------------ *)

let load_stack vm (s : State.t) : Stack.t =
  List.fold_right
    (fun v st -> Stack.push v st)
    s
    (Stack.create ~stack_capacity:vm.stack_capacity)

let to_state (st : Stack.t) : State.t =
  Stack.to_list st

(* ------------------------------------------------------------ *)
(* Pure semantics for normal instructions                       *)
(* ------------------------------------------------------------ *)

let eval_normal instr st emit =
  match instr with
  | Pop ->
      let _, st = pop st in
      st

  | Emit ->
      emit "default" (peek st);
      st

  | EmitTo name ->
      emit name (peek st);
      st

  | EmitIfNonZero name ->
      let v = peek st in
      if v <> 0 then emit name v;
      st

  | Add ->
      let a, st = pop st in
      let b, st = pop st in
      push (a + b) st

  | AddMod ->
      let input, st = pop st in
      let acc, st = pop st in
      let ceil = peek st in
      let sum = acc + input in
      if sum < ceil then
        push 0 (push sum st)
      else
        push 1 (push (sum - ceil) st)

  | PushConst n ->
      push n st

  | LogStack ->
      Printf.printf "Stack: [%s]\n"
        (String.concat "; "
           (List.map string_of_int (Stack.to_list st)));
      st

  | _ ->
      failwith "eval_normal: unexpected control instruction"


(* ------------------------------------------------------------ *)
(* Execute a single instruction                                 *)
(* ------------------------------------------------------------ *)

let exec_instr st instr : control * Stack.t * (string * int) list =
  let outs = ref [] in
  let emit name v = outs := (name, v) :: !outs in

  match instr with
  (* --- Control instructions --- *)
  | Instructions.Halt ->
      (Halt, st, !outs)

  | Instructions.HaltIfEq (n, x) ->
      let v = Stack.get_nth st n in
      if v = x then (Halt, st, !outs)
      else (Continue, st, !outs)

  (* --- Normal instructions --- *)
  | _ ->
      let st' = eval_normal instr st emit in
      (Continue, st', !outs)


(* ------------------------------------------------------------ *)
(* Execute a full program                                       *)
(* ------------------------------------------------------------ *)

let exec_program
    (vm : t)
    (state : State.t)
    (code : instr list)
    (payload : int)
  : State.t * (string * int) list * bool
  =
  let st = load_stack vm state in
  let st = push payload st in

  let outputs = ref [] in

  let rec loop st pc steps =
    if steps >= vm.max_steps then
      failwith "VM: max_steps limit exceeded"
    else if pc < 0 || pc >= List.length code then
      (st, false)
    else
      let instr = List.nth code pc in
      let (ctl, st', outs) = exec_instr st instr in
      outputs := outs @ !outputs;
      match ctl with
      | Continue ->
          loop st' (pc + 1) (steps + 1)
      | Halt ->
          (st', true)
  in

  let final_stack, halted = loop st 0 0 in
  (to_state final_stack, !outputs, halted)
