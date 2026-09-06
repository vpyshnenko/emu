open Emu.Instructions
open Layout


(* =========================================================================
   2. RX HANDLER (Receiving a routed packet from a neighbor node)
   Incoming Payload on input.rx: [DestNodeId; Gen]
   Outgoing Payload on output.rx: [DestNodeId; Gen  + 1]
   Outgoing Payload on output.data: [1]
   ========================================================================= *)
let rx = [
  (* Check Mem idx available for Gen Storage *)
  LoadPayload 1;
  LoadMeta MemLen;
  Sub;
  GePop 0;
  BranchOf [| [Halt] |];
  
  (* --- A. Update total count of received messages --- *)
  LoadTo mem.count;
  PushConst 1;
  Add;
  StoreTo mem.count;
  Pop;
  
  (* --- A. Update generation count of received messages  --- *)
  LoadPayload 1;   (* stack: [GenIdx] *)
  Load;            (* stack: [Mem[GenIdx]; GenIdx] *)
  PushConst 1;
  Add;             (* stack: [Mem[GenIdx]+1; GenIdx] *)
  PopA;            (* stack: [GenIdx]     regA <- Mem[GenIdx]+1; *)
  Store;           (* mem.(GenIdx) <-  Mem[GenIdx]+1; *)
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
      LoadPayload 1;
	  PushConst 1;
	  Add; PopToOut;          (* out_buf <- [inc gen] *)
	  LoadPayload 0; PopToOut;  (* forward incoming payload [DestNodeId; Gen] *)
      SendTo output.tx;         (* Keep transmitting over 'tx' [4] *)
    ];
    (* Branch 1: TARGET REACHED! Success! [8] *)
    [
      PushConst 1;                        (* out_buf <- [1] *)
      PopToOut;                              
      SendTo output.data;                   (* Emit Register A content on 'data' port [4] *)
    ]
  |];
]

let handlers = make_handlers ~rx