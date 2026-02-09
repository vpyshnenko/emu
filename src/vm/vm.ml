(* vm.ml *)

open Instructions
open Stack

(* ------------------------------------------------------------ *)
(* VM configuration                                             *)
(* ------------------------------------------------------------ *)

type t = {
  stack_capacity : int;
  max_steps      : int;
  mem_size       : int;
}

type control =
  | Continue
  | Halt

let create ~stack_capacity ~max_steps ~mem_size =
  { stack_capacity; max_steps; mem_size }

let empty = { stack_capacity = 0; max_steps = 0; mem_size = 0 }

(* ------------------------------------------------------------ *)
(* Pure semantics for normal instructions                       *)
(* ------------------------------------------------------------ *)

let eval_normal
    (instr : instr)
    (st : Stack.t)
    ~(mem : int array)
    ~(meta_mem : int array)
    ~(regA : int ref)
    ~(emit : int -> unit)
    ~(out_port_count : int)
  : Stack.t =
  match instr with
  (* --- Stack operations --- *)
  | Pop ->
      let _, st = pop st in
      st

  | PushConst n ->
      push n st

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

  | LogStack ->
      Printf.printf "Stack: [%s]\n"
        (String.concat "; "
           (List.map string_of_int (Stack.to_list st)));
      st

  (* --- Accumulator A operations --- *)
  | PushA ->
      push !regA st

  | PopA ->
      let v, st = pop st in
      regA := v;
      st

  | PeekA ->
      regA := peek st;
      st

  (* --- Persistent memory (RAM) --- *)
  | Load i ->
      if i < 0 || i >= Array.length mem then
        failwith "VM: Load index out of bounds"
      else
        push mem.(i) st

  | Store i ->
      if i < 0 || i >= Array.length mem then
        failwith "VM: Store index out of bounds"
      else
        let v = peek st in
        mem.(i) <- v;
        st

  (* --- Metadata memory (meta_mem) --- *)
  | LoadMeta i ->
      if i < 0 || i >= Array.length meta_mem then
        failwith "VM: LoadMeta index out of bounds"
      else
        push meta_mem.(i) st

  (* --- Emission instructions (emit regA) --- *)
  | Emit ->
      let idx = peek st in
      if idx < 0 || idx >= out_port_count then
        failwith "VM: Emit index out of bounds"
      else (
        emit idx;
        st
      )

  | EmitTo idx ->
      if idx < 0 || idx >= out_port_count then
        failwith "VM: EmitTo index out of bounds"
      else (
        emit idx;
        st
      )

  | EmitIfNonZero idx ->
      let cond = peek st in
      if cond <> 0 then (
        if idx < 0 || idx >= out_port_count then
          failwith "VM: EmitIfNonZero index out of bounds"
        else emit idx
      );
      st

  (* --- Control instructions should not reach here --- *)
  | Halt
  | HaltIfEq _ ->
      failwith "eval_normal: unexpected control instruction"

(* ------------------------------------------------------------ *)
(* Execute a single instruction                                 *)
(* ------------------------------------------------------------ *)

let exec_instr
    (st : Stack.t)
    (instr : instr)
    ~(mem : int array)
    ~(meta_mem : int array)
    ~(regA : int ref)
    ~(out_port_count : int)
  : control * Stack.t * (int * int) list =
  let outs = ref [] in
  let emit idx =
    outs := (idx, !regA) :: !outs
  in
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
      let st' =
        eval_normal instr st ~mem ~meta_mem ~regA ~emit ~out_port_count
      in
      (Continue, st', !outs)

(* ------------------------------------------------------------ *)
(* Execute a full program                                       *)
(* ------------------------------------------------------------ *)

let exec_program
    (vm : t)
    (state : State.t)
    (meta_info : int list)
    (code : instr list)
    (payload : int)
    (out_port_count : int)
  : State.t * (int * int) list * bool
  =
  (* Convert node state list -> RAM array, padding if needed *)
  let mem =
    let len = List.length state in
    if len > vm.mem_size then
      failwith "VM: state exceeds memory size";
    Array.init vm.mem_size (fun i ->
      if i < len then List.nth state i else 0
    )
  in

  (* Convert meta_info list -> meta_mem array *)
  let meta_mem = Array.of_list meta_info in

  (* Register A starts with incoming payload *)
  let regA = ref payload in

  (* Operational stack starts empty *)
  let st = Stack.create ~stack_capacity:vm.stack_capacity in

  let outputs = ref [] in

  let rec loop st pc steps =
    if steps >= vm.max_steps then
      failwith "VM: max_steps limit exceeded"
    else if pc < 0 || pc >= List.length code then
      (st, false)
    else
      let instr = List.nth code pc in
      let (ctl, st', outs) =
        exec_instr st instr ~mem ~meta_mem ~regA ~out_port_count
      in
      outputs := outs @ !outputs;
      match ctl with
      | Continue ->
          loop st' (pc + 1) (steps + 1)
      | Halt ->
          (st', true)
  in

  let _final_stack, halted = loop st 0 0 in

  (* Pack RAM back into node state list *)
  let final_state = Array.to_list mem in
  (final_state, !outputs, halted)
