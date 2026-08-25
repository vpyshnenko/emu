(* handlers.ml *)
open Emu.Instructions
open Layout


let ping_init = [
  LoadMeta NodeId;
  PushA;
  SendTo (output.ping, 2)
]
    


let ping = [
  LoadPayload 0;
  LoadMeta NodeId;
  Sub;
  NonEqPop 0;
  BranchOf [| [
      LoadPayload 1;
	  LoadPayload 0;
	  SendTo (output.ping, 2);
	  Halt
    ]
  |];
  
  LoadMeta NodeId;
  LoadPayload 1;
  SendTo (output.pong, 2);
]

let pong = [
  LoadPayload 0;
  LoadMeta NodeId;
  Sub;
  NonEqPop 0;
  BranchOf [| [ 
      LoadPayload 1;
	  LoadPayload 0;
	  SendTo (output.pong, 2);
	  Halt 
    ]
  |];
  PushConst 1;
  PopA;
  EmitTo output.ok
]


(* =========================================================================
   BINDING HANDLERS
   ========================================================================= *)
let handlers = make_handlers ~ping_init ~ping ~pong