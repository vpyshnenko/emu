open Emu.Instructions
open Layout

(* =========================================================================
   STP INIT HANDLER: Triggered on the Root node to initiate STP.
   ========================================================================= *)
let stp_init = [
  (* Set Parent Node ID to -1 (indicates "I am the Root" or "No Parent") *)
  PushConst (-1);
  Store mem.leader_id;                 (* RAM[parent_node_id] <- -1 *)
  Pop;                                      (* Clean up the stack *)
  
  (* Root's distance to itself is 0 *)
  PushConst 0;
  Store mem.distance;                       (* RAM[distance] <- 0 *)
  
  (* Prepare to broadcast our distance to neighbor nodes *)
  LoadMeta NodeId;
  SendTo (output.stp, 2);               (* Sends [LeaderId; Distance] to neighbors *)
]

(* =========================================================================
   STP HANDLER: Processes incoming distance advertisements from neighbors.
   ========================================================================= *)
let stp = [
  (* Calculate proposed distance: incoming distance (passed in Register A) + 1 *)
  LoadPayload 1;                        (* Push received distance onto the stack *)
  PushConst 1;
  Add;                                      (* Stack: [ proposed_distance ] *)
  (* Compare proposed distance with our current stored distance *)
  Dup;                      (* Stack: [ proposed_distance; proposed_distance ] *)
  Load mem.distance;        (* Stack: [ current_distance; proposed_distance; proposed_distance ] *)
  Sub;                      (* Stack: [ (current_distance - proposed_distance); proposed_distance ] *)
  LtPop 0;                  (* Pops comparison result. If (current - proposed) > 0 (meaning proposed < current), pushes 1 (True), else 0 *)
  
  (* If proposed_distance is smaller, update our routing state *)
  BranchOf [|
    (* --- UPDATE ROUTING STATE BRANCH --- *)
    [

      (* Update our stored distance to the new, shorter distance *)
      Store mem.distance;                   (* RAM[distance] <- proposed_distance *)
            (* Update parent to the node that advertised this shorter path *)
      LoadPayload 0;                (* Load the new LeaderId *)
      Store mem.leader_id;             (* RAM[leader_id] <- LeaderId *)
	  
      (* Propagate the updated distance down the tree *)
	  SendTo (output.stp, 2)  (* Broadcast [LeaderId; Distance] to our neighbors *)
    ];
  |];
]
(* =========================================================================
   SEND HANDLER (Triggered externally to start a transfer of Val to DestNodeId)
   Incoming Payload on input.send: [DestNodeId; Val]
   We automatically increment our seq_id and broadcast: [NewSeqId; DestNodeId; Val]
   ========================================================================= *)
let send = [
  (* --- A. AUTO-INCREMENT SEQUENCE IDENTIFIER --- *)
  Load mem.seq_id;                           (* Stack: [seq_id] *)
  PushConst 1;                              (* Stack: [1; seq_id] *)
  Add;                                      (* Stack: [seq_id + 1] *)
  Store mem.seq_id;                          (* RAM[seq_id] <- seq_id + 1 *)
  Pop;                                      (* Clear the stack *)
  
  (* --- B. PREPARE PACKET to Root [SeqId; TTL; LeaderId; DestNodeId; FromNodeId; Val] - *)  LoadPayload 1;                   (* Push Val *)
  LoadMeta NodeId;                 (* Push FromNodeId *)
  LoadPayload 0;                   (* Push DestNodeId *)
  Load mem.distance;                (* Push TTL (Time-To-Live *)
  Load mem.leader_id;              (* Push LeaderId *)
  
  (* --- C. BROADCAST WAVE --- *)
  SendTo (output.root_tx, 5);         (* Sends [ttl; leader_id; ToNodeId; FromNodeId, Val] to neighbors *)
]

(* =========================================================================
   ROOT_RX HANDLER 
   Incoming Payload on input.root_rx: [LeaderId; TTL; DestNodeId; FromNodeId, Val]
   ========================================================================= *)
let root_rx = [
  PushA;				(* Push LeaderId *)
  LoadMeta NodeId;
  Sub;
  NonEqPop 0;
  BranchOf [|
    [
	  LoadPayload 1;    (* Push TTL *)
	  PushConst (-1);
	  Add;
	  PeekA;   (* Copy temporary TTL to RegA *)
	  LePop 0;
	  BranchOf [| [ Halt ] |];
	  LoadPayload 4;
	  LoadPayload 3;
	  LoadPayload 2;
	  PushA;   (* Push TTL on stack from RegA *)
	  LoadPayload 1;
	  SendTo (output.root_tx, 5)
	];
	[
	  LoadPayload 2;
	  LoadMeta NodeId;
	  Sub;
	  EqPop 0;
	  BranchOf [|
	    [
		  LoadPayload 4;
		  EmitTo output.data;
		  Halt;
		];
	    [
		  LoadPayload 4;
		  LoadPayload 3;
		  LoadPayload 2;
		  Load mem.seq_id;
		  PushConst 1;
		  Add;
		  Store mem.seq_id;
		  SendTo (output.tx, 4)
		]		
	  |]
	]
  |]
]

(* =========================================================================
   RX HANDLER 
   Incoming Payload on input.rx: [SeqId; DestNodeId; FromNodeId, Val]
   ========================================================================= *)
let rx = [
  PushA;                                    (* Push Incoming SeqId (from regA) *)
  Load mem.seq_id;                           (* Push Cached seq_id from RAM *)
  Sub;     
  GtPop 0;                                  (* Compares (Incoming - Cached) > 0 and pops [7].
                                               Pushes 0 (New Session) or 1 (Old/Duplicate). *)
  BranchOf [|
    (* Branch 0: New sequence accepted -> Update local cache and proceed [8] *)
    [
      PushA;                                (* Push the Incoming SeqId from regA *)
      Store mem.seq_id;                      (* RAM[seq_id] <- Incoming SeqId [4] *)
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
      LoadPayload 3;                        (* Push Val *)
      LoadPayload 2;                        (* Push FromNodeId *)
      LoadPayload 1;                        (* Push DestNodeId *)
      LoadPayload 0;                        (* Push SeqId *)
      SendTo (output.tx, 4);                (* Keep transmitting over 'tx' [4] *)
    ];
    (* Branch 1: TARGET REACHED! Success! [8] *)
    [
      LoadPayload 3;                        (* Push Val (payload index 3) *)
      PopA;                                 (* Store Val in Register A [2] *)
      EmitTo output.data;                   (* Emit Register A content on 'data' port [4] *)
    ]
  |];
]

let handlers = make_handlers ~stp_init ~stp ~send ~root_rx ~rx 