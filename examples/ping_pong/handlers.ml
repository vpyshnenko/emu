open Emu.Instructions
open Layout

(* =========================================================================
   1. SEND HANDLER (Triggered externally to start a transfer of Val to DestNodeId)
   Incoming Payload on input.send: [DestNodeId; Val]
   We automatically increment our seqId and broadcast: [NewSeqId; DestNodeId; Val]
   ========================================================================= *)
let send = [
  (* --- A. AUTO-INCREMENT SEQUENCE IDENTIFIER --- *)
  Load mem.seqId;                           (* Stack: [seqId] *)
  PushConst 1;                              (* Stack: [1; seqId] *)
  Add;                                      (* Stack: [seqId + 1] *)
  Store mem.seqId;                          (* RAM[seqId] <- seqId + 1 *)
  Pop;                                      (* Clear the stack *)
  
  (* --- B. PREPARE PACKET [NewSeqId; DestNodeId; Val] ---
     To emit a packet containing [NewSeqId; DestNodeId; Val] via SendTo,
     we must push them onto the stack in REVERSE order (tail elements first) [4, 5].
     Stack top-to-bottom must be: [NewSeqId; DestNodeId; Val]
     So we push: Val, then DestNodeId, then NewSeqId. *)
  LoadPayload 1;                            (* Push Val (payload index 1 of the send trigger) [3] *)
  LoadPayload 0;                            (* Push DestNodeId (payload index 0 of the send trigger) *)
  Load mem.seqId;                           (* Push our newly incremented seqId [2] *)
  
  (* --- C. BROADCAST WAVE --- *)
  SendTo (output.tx, 3);                    (* Sends [NewSeqId; DestNodeId; Val] to neighbors [4] *)
]

(* =========================================================================
   2. RX HANDLER (Receiving a routed packet from a neighbor node)
   Incoming Payload on input.rx: [SeqId; DestNodeId; Val]
   ========================================================================= *)
let rx = [
  (* --- A. LOOP GUARD (Deduplication Check) ---
     Because SeqId is at index 0 of the payload, regA is preloaded with SeqId
     at startup [1]. We push it immediately using PushA, saving an array lookup [2]! *)
  PushA;                                    (* Push Incoming SeqId (from regA) *)
  Load mem.seqId;                           (* Push Cached seqId from RAM *)
  Sub;                                      (* Stack: [Incoming - Cached] [6] *)
  GtPop 0;                                  (* Compares (Incoming - Cached) > 0 and pops [7].
                                               Pushes 0 (New Session) or 1 (Old/Duplicate). *)
  BranchOf [|
    (* Branch 0: New sequence accepted -> Update local cache and proceed [8] *)
    [
      PushA;                                (* Push the Incoming SeqId from regA *)
      Store mem.seqId;                      (* RAM[seqId] <- Incoming SeqId [4] *)
      Pop;                                  (* Pop the remaining value left by Store *)
    ];
    (* Branch 1: Old or duplicate sequence -> Discard packet immediately *)
    [ Halt ]
  |];

  (* --- B. DESTINATION CHECK ---
     Is DestNodeId (payload index 1) equal to our own NodeId? [3] *)
  LoadPayload 1;                            (* Push DestNodeId *)
  LoadMeta NodeId;                          (* Push our own NodeId [4] *)
  Sub;                                      (* Stack: [OurNodeId - DestNodeId] *)
  NonEqPop 0;                               (* Compares StackTop <> 0 and pops [7].
                                               Pushes 0 (Transit: not equal) or 1 (Target: equal). *)
  BranchOf [|
    (* Branch 0: TRANSIT NODE -> Forward packet to neighbors [8] *)
    [
      LoadPayload 2;                        (* Push Val *)
      LoadPayload 1;                        (* Push DestNodeId *)
      LoadPayload 0;                        (* Push SeqId *)
      SendTo (output.tx, 3);                (* Keep transmitting over 'tx' [4] *)
      Halt;
    ];
    (* Branch 1: TARGET REACHED! Success! [8] *)
    [
      LoadPayload 2;                        (* Push Val (payload index 2) *)
      PopA;                                 (* Store Val in Register A [2] *)
      EmitTo output.data;                   (* Emit Register A content on 'data' port [4] *)
      Halt;
    ]
  |];
]

let handlers = make_handlers ~send ~rx