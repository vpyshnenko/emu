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
  
  | Eq of int  (* Compare top of stack with constant X *)
  | Gt of int  
  | Lt of int  
  | Ge of int  
  | Le of int  
  
  
  | PushA
  | PopA
  | PeekA
  
  | Load of int
  | Store of int
  | LoadMeta of Meta.index
  

  (* Emission instructions *)
  | Emit                  (* send regA content to port defined by top of stack *)
  | EmitTo of int         (* send regA content to port by index *)

  (* Control flow *)
  | Halt (* early return *)
  | Shutdown (* exclude curent node from further network evaluation *)
  | BranchOf of instr list array
  | Loop of instr list 
  
