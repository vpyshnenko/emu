(* instructions.ml *)

type instr =
  (* Stack operations *)
  | Pop
  | PushConst of int
  | Add
  | AddMod
  | LogStack

  (* Emission instructions *)
  | Emit                     (* send head of stack to port 0 ("default") *)
  | EmitTo of string         (* send head of stack to port aliased by label *)

  (* Conditional emission *)
  | EmitIfNonZero of string  (* same, but only if top-of-stack ≠ 0 *)

  (* Control flow *)
  | Halt
  | HaltIfEq of int * int
