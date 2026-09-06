open Emu.Instructions
open Layout


(* =========================================================================
   2. RX HANDLER (Receiving a routed packet from a neighbor node)
   Incoming Payload on input.rx: [DestNodeId; Val]
   Outgoing Payload on output.rx: [DestNodeId; Val]
   Outgoing Payload on output.data: [Val]
   ========================================================================= *)
let rx = [
  (* --- A. Update count of received messages --- *)
  LoadTo mem.count;
  PushConst 1;
  Add;
  StoreTo mem.count;
  Pop;
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
      CopyPayloadToOut 0;  (* forward incoming payload [DestNodeId; Val] *)
      SendTo output.tx;                (* Keep transmitting over 'tx' [4] *)
    ];
    (* Branch 1: TARGET REACHED! Success! [8] *)
    [
      LoadPayload 1;                        (* out_buf <- [Val] *)
      PopToOut;                              
      SendTo output.data;                   (* Emit Register A content on 'data' port [4] *)
    ]
  |];
]

let handlers = make_handlers ~rx