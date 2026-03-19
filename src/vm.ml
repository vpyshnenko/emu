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
  | Shutdown

type exec_result = {
  st : Stack.t;
  control : control;
  remaining_code : instr list;  (* Instructions left to execute *)
}

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
	  
  | Eq x ->
     let top = peek st in  (* Peek, don't pop *)
     if top = x then
       push 0 st    (* Equal -> push 0 on top *)
     else
       push 1 st    (* Not equal -> push 1 on top *)
	   
  | Gt x ->
      let top = peek st in
      if top > x then push 0 st else push 1 st
  
  | Lt x ->
      let top = peek st in
      if top < x then push 0 st else push 1 st
  
  | Ge x ->
      let top = peek st in
      if top >= x then push 0 st else push 1 st
  
  | Le x ->
      let top = peek st in
      if top <= x then push 0 st else push 1 st

  | Add ->
      let a, st = pop st in
      let b, st = pop st in
      push (a + b) st

  | AddMod ->
      let input, st = pop st in
      let acc, st = pop st in
      let ceil, st = pop st in
      let sum = acc + input in
      if sum < ceil then
        push 0 (push sum st)
      else
        push 1 (push (sum - ceil) st)
		
  | Shl ->
     let shift, st = pop st in
     let value, st = pop st in
     push (value lsl shift) st (* logical shift left *)

  | Shr ->
      let shift, st = pop st in
      let value, st = pop st in
      push (value lsr shift) st  (* logical shift right *)

  | LogStack ->
      Printf.printf "(Node %d) Stack: [%s]\n" meta_mem.(0)
        (String.concat "; "
           (List.map string_of_int (Stack.to_list st)));
      st
  | LogMem ->
      Printf.printf "(Node %d) Mem: [%s]\n" meta_mem.(0)
        (String.concat "; "
           (Array.to_list mem |> List.map string_of_int));
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
  | LoadMeta meta ->
      let i = Meta.to_int meta in
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

  (* --- Control instructions should not reach here --- *)
  | Halt
  | Shutdown
  | BranchOf _ ->
      failwith "eval_normal: unexpected control instruction"

(* ------------------------------------------------------------ *)
(* Execute a single instruction                                 *)
(* (outs are appended directly into the program output buffer) *)
(* ------------------------------------------------------------ *)

let exec_instr
    (st : Stack.t)
    (instr : instr)
    (rest_code : instr list)  (* Remaining code after this instruction *)
    ~(mem : int array)
    ~(meta_mem : int array)
    ~(regA : int ref)
    ~(emit : int -> unit)
    ~(out_port_count : int)
  : exec_result =
  match instr with
  (* --- Control instructions --- *)
  | Instructions.Halt ->
      { st; control = Halt; remaining_code = [] }
  | Instructions.Shutdown ->
      { st; control = Shutdown; remaining_code = [] }

  (* --- New Branches instruction --- *)
  | Instructions.BranchOf branches ->
      let idx, st' = pop st in
      
      if idx >= 0 && idx < Array.length branches then
        (* Valid branch - prepend its instructions to the rest of the program *)
        let branch_code = branches.(idx) in
        { 
          st = st'; 
          control = Continue; 
          remaining_code = branch_code @ rest_code  (* Prepend branch, then continue with rest *)
        }
      else
        (* Invalid index - just continue with rest of program *)
        { st = st'; control = Continue; remaining_code = rest_code }

  (* --- Normal instructions --- *)
  | _ ->
      let st' =
        eval_normal instr st ~mem ~meta_mem ~regA ~emit ~out_port_count
      in
      { st = st'; control = Continue; remaining_code = rest_code }

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

  (* Ordered program output buffer (Snoc) *)
  let outputs_q : (int * int) Snoc.t = Snoc.create () in

  (* Emit closure appends directly into Snoc buffer *)
  let emit idx =
    Snoc.add outputs_q (idx, !regA)
  in

  let rec loop st remaining_code steps =
    if steps >= vm.max_steps then
      failwith "VM: max_steps limit exceeded"
    else
      match remaining_code with
      | [] -> 
          (* No more code to execute *)
          (st, false)
      | instr :: rest ->
          let result = 
            exec_instr st instr rest 
              ~mem ~meta_mem ~regA ~emit ~out_port_count
          in
          match result.control with
		  | Halt ->
              (result.st, false)
          | Shutdown ->
              (result.st, true)
          | Continue ->
              loop result.st result.remaining_code (steps + 1)
  in

  let _final_stack, halted = loop st code 0 in

  (* Pack RAM back into node state list *)
  let final_state = Array.to_list mem in

  (* Outputs in chronological emission order across the program *)
  let outputs = Snoc.to_list outputs_q in

  (final_state, outputs, halted)

