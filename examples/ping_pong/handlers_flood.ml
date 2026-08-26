open Emu.Instructions
open Layout


let send = [
  LoadPayload 1;                 (* 1. Push Val *)
  PushA;                         (* 2. Push DestNodeId *)
  SendTo (output.tx, 2);       (* 3. Emit [DestNodeId; Val] *)
]

(* =========================================================================
   2. RX HANDLER (Receiving a routed packet from a neighbor node)
   Incoming Payload on input.rx: [DestNodeId; Val]
   ========================================================================= *)
let rx = [
  (* --- B. DESTINATION CHECK ---
     Is DestNodeId (payload index 1) equal to our own NodeId? [3] *)
  LoadPayload 0;                            (* Push DestNodeId *)
  LoadMeta NodeId;                          (* Push our own NodeId [4] *)
  Sub;                                      (* Stack: [OurNodeId - DestNodeId] *)
  NonEqPop 0;                               (* Compares StackTop <> 0 and pops [7].
                                               Pushes 0 (Transit: not equal) or 1 (Target: equal). *)
  BranchOf [|
    (* Branch 0: TRANSIT NODE -> Forward packet to neighbors [8] *)
    [
      LoadPayload 1;                        (* Push Val *)
      LoadPayload 0;                        (* Push DestNodeId *)
      SendTo (output.tx, 2);                (* Keep transmitting over 'tx' [4] *)
    ];
    (* Branch 1: TARGET REACHED! Success! [8] *)
    [
      LoadPayload 1;                        (* Push Val (payload index 1) *)
      PopA;                                 (* Store Val in Register A *)
      EmitTo output.data;                   (* Emit Register A content on 'data' port [4] *)
    ]
  |];
]

let handlers = make_handlers ~send ~rx