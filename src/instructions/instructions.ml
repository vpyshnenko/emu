(* instructions.ml *)

type instr =
  (* Stack operations *)
  | Pop
  | PushConst of int
  | Add
  | AddMod
  | LogStack
  
  | PushA
  | PopA
  | PeekA
  
  | Load of int
  | Store of int
  | LoadMeta of int
  

  (* Emission instructions *)
  | Emit                  (* send regA content to port defined by top of stack *)
  | EmitTo of int         (* send regA content to port by index *)

  (* Conditional emission *)
  | EmitIfNonZero of int  (* same, but only if top-of-stack ≠ 0 *)

  (* Control flow *)
  | Halt
  | HaltIfEq of int * int
