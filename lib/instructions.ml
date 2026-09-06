(* instructions.ml *)

type instr =
  (* Stack operations *)
  | Dup
  
  | Pop
  | PushConst of int
  | Add
  | AddMod
  | Sub
  | Shl
  | Shr
  
  | LogStack
  | LogMem
  | LogPayload
  | LogOut
  
  | Eq of int  (* Compare top of stack with constant X *)
  | NonEq of int (* Compare top of stack for inequality with constant X (peek) *)
  | Gt of int  
  | Lt of int  
  | Ge of int  
  | Le of int  
  | EqPop of int (* Pop: compares top of stack with X, pops the operand *)
  | NonEqPop of int (* Compare top of stack for inequality with constant X and pop *)
  | GtPop of int
  | LtPop of int
  | GePop of int
  | LePop of int
  
  
  | PushA
  | PopA
  | PeekA
  
  | LoadTo of int
  | Load
  | StoreTo of int
  | Store
  | LoadMeta of Meta.index
  

  (* Emission instructions *)
  | Emit                  (* send regA content to port defined by top of stack *)
  | EmitTo of int         (* send regA content to port by index *)
  | LoadPayload of int    (* load payload element by index *)
  | SendTo of int
  | CopyPayloadToOut of int
  | PopToOut

  | Fail (* fail on purpose *)
  
  
  (* Control flow *)
  | Halt (* early return *)
  | Shutdown (* exclude curent node from further network evaluation *)
  | BranchOf of instr list array
  | Loop of instr list 
  
let string_of_instr = function
  | Dup -> "Dup"
  | Pop -> "Pop"
  | PushConst n -> Printf.sprintf "PushConst %d" n
  | Add -> "Add"
  | AddMod -> "AddMod"
  | Sub -> "Sub"
  | Shl -> "Shl"
  | Shr -> "Shr"
  | LogStack -> "LogStack"
  | LogMem -> "LogMem"
  | LogPayload -> "LogPayload"
  | LogOut -> "LogOut"
  | Eq x -> Printf.sprintf "Eq %d" x
  | NonEq x -> Printf.sprintf "NonEq %d" x
  | Gt x -> Printf.sprintf "Gt %d" x
  | Lt x -> Printf.sprintf "Lt %d" x
  | Ge x -> Printf.sprintf "Ge %d" x
  | Le x -> Printf.sprintf "Le %d" x
  | EqPop x -> Printf.sprintf "EqPop %d" x
  | NonEqPop x -> Printf.sprintf "NonEqPop %d" x
  | GtPop x -> Printf.sprintf "GtPop %d" x
  | LtPop x -> Printf.sprintf "LtPop %d" x
  | GePop x -> Printf.sprintf "GePop %d" x
  | LePop x -> Printf.sprintf "LePop %d" x
  | PushA -> "PushA"
  | PopA -> "PopA"
  | PeekA -> "PeekA"
  | LoadTo i -> Printf.sprintf "LoadTo %d" i
  | Load -> "Load"
  | StoreTo i -> Printf.sprintf "StoreTo %d" i
  | Store -> "Store"
  | LoadMeta _ -> "LoadMeta"
  | Emit -> "Emit"
  | EmitTo i -> Printf.sprintf "EmitTo %d" i
  | LoadPayload idx -> Printf.sprintf "LoadPayload %d" idx
  | SendTo p -> Printf.sprintf "SendTo %d" p
  | CopyPayloadToOut idx -> Printf.sprintf "CopyPayloadToOut %d" idx
  | PopToOut -> "PopToOut"
  | Fail -> "Fail"
  | Halt -> "Halt"
  | Shutdown -> "Shutdown"
  | BranchOf _ -> "BranchOf [...]"
  | Loop _ -> "Loop [...]"