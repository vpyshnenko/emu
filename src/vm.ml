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
	~(payload_buf : int array)        
    ~(regA : int ref)
    ~(emit : int -> Payload.t -> unit)
  : Stack.t =
  match instr with
  (* --- Stack operations --- *)
  | Dup ->
    if is_empty st then
      failwith "VM: Dup on empty stack"
    else
      let top = peek st in
      push top st
  
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
	   
  | NonEq x -> 
      let top = peek st in 
      if top <> x then push 0 st else push 1 st
	   
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
	  
  | EqPop x -> 
      let top, st' = pop st in 
      if top = x then push 0 st' else push 1 st'
	  
  | NonEqPop x -> 
      let top, st' = pop st in 
      if top <> x then push 0 st' else push 1 st'
	  
  | GtPop x -> 
      let top, st' = pop st in 
      if top > x then push 0 st' else push 1 st'
	  
  | LtPop x -> 
      let top, st' = pop st in 
      if top < x then push 0 st' else push 1 st'
	  
  | GePop x -> 
      let top, st' = pop st in 
      if top >= x then push 0 st' else push 1 st'
	  
  | LePop x -> 
    let top, st' = pop st in 
    if top <= x then push 0 st' else push 1 st'

  | Add ->
      let a, st = pop st in
      let b, st = pop st in
      push (a + b) st
	  
  | Sub ->
      let a, st = pop st in
      let b, st = pop st in
      push (b - a) st

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
      emit idx [!regA];
      st

  | EmitTo idx ->
      emit idx [!regA];
      st
	  
  | SendTo (out_port, count) ->
    let packet, st' = Stack.pop_n st count in
    emit out_port packet;
    st'
	
  | LoadPayload idx ->
      if idx < 0 || idx >= Array.length payload_buf then
        failwith (Printf.sprintf "VM: LoadPayload index %d out of bounds (size=%d)" idx (Array.length payload_buf))
      else
        Stack.push payload_buf.(idx) st

  (* --- Control instructions should not reach here --- *)
  | Halt
  | Shutdown
  | BranchOf _
  | Loop _ ->
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
	~(payload_buf : int array)        
    ~(regA : int ref)
    ~(emit : int -> Payload.t -> unit)
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
  | Instructions.Loop body ->
      let cond, st' = pop st in
      if cond = 0 then
        { st = st'; control = Continue; remaining_code = rest_code }
      else
        let loop_code = body @ [Instructions.Loop body] @ rest_code in
        { st = st'; control = Continue; remaining_code = loop_code }

  (* --- Normal instructions --- *)
  | _ ->
      let st' =
        eval_normal instr st ~mem ~meta_mem ~payload_buf ~regA ~emit
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
    (payload : Payload.t)
  : State.t * (int * Payload.t ) list * bool
  =
  let payload_buf = Array.of_list payload in
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
  (* let payload_buf = Array.of_list payload in *)
  
  (* Register A starts with incoming payload *)
  let regA = ref (
    match payload with 
    | head :: _ -> head 
    | [] -> failwith "VM: Cannot execute program with an empty payload packet"
  ) in

  (* Operational stack starts empty *)
  let st = Stack.create ~stack_capacity:vm.stack_capacity in

  (* Ordered program output buffer (Snoc) *)
  let outputs_q : (int * Payload.t) Snoc.t = Snoc.create () in

  (* Emit closure appends directly into Snoc buffer *)
  let emit idx values =
    Snoc.add outputs_q (idx, values)
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
              ~mem ~meta_mem ~payload_buf ~regA ~emit
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

