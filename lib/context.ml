(* context-v3.ml *)
(* Encapsulated execution context for the emulator.
   Prevents direct structure dependency from other modules while keeping updates extremely fast. *)

(* Emu_Vm_Exec_Error (VmStep, Instr, msg) *)
exception Emu_Vm_Exec_Error of int * Instructions.instr * string


type field =
  | NodeId of int
  | InPort of int
  | SenderId of int
  | Payload of int list
  | VmStep of int
  | Instr of Instructions.instr

type t = {
  mutable node_id   : int option;
  mutable in_port   : int option;
  mutable sender_id : int option;
  mutable out_port  : int option;
  mutable payload   : int list option;
  mutable vm_step      : int option;
  mutable instr     : Instructions.instr option;
}

let create () = {
  node_id   = None;
  in_port   = None;
  sender_id = None;
  out_port  = None;
  payload   = None;
  vm_step      = None;
  instr     = None;
}

(* Inline-friendly, fast property updater *)
let build 
    ?node_id 
    ?in_port 
    ?sender_id 
    ?out_port 
    ?payload 
    ?vm_step 
    ?instr 
    ?ctx 
    () =
  let c = match ctx with
    | Some existing -> existing
    | None -> create ()
  in
  (* Если поле передано, обновляем значение (оно уже завернуто в Some) *)
  (match node_id with Some _ -> c.node_id <- node_id | None -> ());
  (match in_port with Some _ -> c.in_port <- in_port | None -> ());
  (match sender_id with Some _ -> c.sender_id <- sender_id | None -> ());
  (match in_port with Some _ -> c.out_port <- out_port | None -> ());
  (match payload with Some _ -> c.payload <- payload | None -> ());
  (match vm_step with Some _ -> c.vm_step <- vm_step | None -> ());
  (match instr with Some _ -> c.instr <- instr | None -> ());
  c

let print ctx =
  let opt_str name f = function
    | Some v -> Printf.sprintf "  %-12s : %s\n" name (f v)
    | None   -> ""
  in
  let dump =
    "\n=================================================================\n" ^
    "⚡ Emu FAILED with following EXECUTION CONTEXT\n" ^
    "=================================================================\n" ^
    opt_str "Node ID" string_of_int ctx.node_id ^
    opt_str "Input Port" string_of_int ctx.in_port ^
    opt_str "Sender ID" string_of_int ctx.sender_id ^
    opt_str "Output Port" string_of_int ctx.out_port ^
    opt_str "Payload" (fun p -> "[" ^ String.concat "; " (List.map string_of_int p) ^ "]") ctx.payload ^
    opt_str "Vm Step Count" string_of_int ctx.vm_step ^
    opt_str "Instruction" Instructions.string_of_instr ctx.instr ^
    "=================================================================\n"
  in
  prerr_endline dump;
