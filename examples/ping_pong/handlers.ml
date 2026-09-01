(* handlers.ml *)
open Emu.Instructions
open Layout

(* =========================================================================
   STP_INIT HANDLER
   Triggered ONLY on the designated Root node to start tree building.
   ========================================================================= *)
let stp_init = [
  (* 1. Set Parent / Leader ID to -1 (indicates "I am the Spanning Tree Root") *)
  PushConst (-1);         (* Stack: [ -1 ] *)
  Store mem.parent_id;    (* RAM[leader_id] <- -1. (Store keeps top of stack) *)
  Pop;                    (* Stack: [] (Clean up the stack) *)

  (* 2. Set root distance to itself as 0 *)
  PushConst 0;            (* Stack: [ 0 ] *)
  Store mem.distance;     (* RAM[distance] <- 0 *)

  (* 3. Broadcast our Root advertisement to all physical neighbors *)
  SendTo (output.stp, 1); (* broadcasts [Distance] *)
  
]


(* =========================================================================
   STP HANDLER
   Triggered on receiving a [Distance] advertisement from a neighbor.
   ========================================================================= *)
let stp = [
  PushA;          (* Stack: [ recv_distance ] *)
  PushConst 1;            (* Stack: [ 1; recv_distance ] *)
  Add;                    (* Stack: [ proposed_distance = recv_distance + 1 ] *)
  PeekA;  (* temp store proposed distance *)

  (* 2. Compare proposed_distance with current stored distance *)
  Load mem.distance;      (* Stack: [ current_dist; proposed_dist; proposed_dist ] *)
  Sub;                    (* Stack: [ (current_dist - proposed_dist); proposed_dist ] *)
  LtPop 0;                
                           
  (* 3. Update routing state if the proposed distance is shorter *)
  BranchOf [|
    (* Branch 0 (True: Proposed distance is shorter -> UPDATE STATE) *)
    [
      LoadMeta SenderNodeId;      (* Stack: [ new_parent_id; proposed_dist ] *)
      Store mem.parent_id;(* RAM[leader_id] <- incoming_leader_id *)
	  
      PushA;    (* restore proposed distance from RegA *)
      Store mem.distance; (* RAM[distance] <- proposed_dist *)

      (* Broadcast updated shortest-path advertisement to neighbors *)
      SendTo (output.stp, 1); (* Pops elements, broadcasts [distance] *)
    ]
  |];
]


(* =========================================================================
   SEND HANDLER
   Triggered externally (e.g. by ext_node) to transfer a value.
   Incoming Payload: [DestNodeId; Val]
   Outgoing Downward Payload: [SeqId; DestNodeId; FromNodeId; Val]
   Outgoing Upward Payload: [ParentId; ToNodeId; FromeNodeId; Val]
   ========================================================================= *)
let send = [
  (* --- OPTIMIZATION A: SHORT-CIRCUIT SELF-SENDING --- *)
  LoadPayload 0;        (* Stack: [ DestNodeId ] *)
  LoadMeta NodeId;      (* Stack: [ OurNodeId; DestNodeId ] *)
  Sub;                  (* Stack: [ OurNodeId - DestNodeId ] *)
  EqPop 0;              (* Pops. If OurNodeId == DestNodeId, pushes 1 (True), else 0 (False) *)
  
  BranchOf [|
    (* Branch 0 (True: Self-sending -> Deliver locally) *)
    [
      LoadPayload 1;      (* Stack: [ Val ] *)
	  SendTo(output.data, 1);
      Halt;               (* Stop VM immediately *)
    ]
  |];

  (* --- OPTIMIZATION B: ROOT DIRECT-FLOOD --- *)
  Load mem.parent_id;      
  EqPop (-1);             
  
  BranchOf [|
    (* Branch 0 (True: Sender is the Root -> Bypasses convergecast, initiate flood) *)
    [
      LoadPayload 1;      (* Stack: [ Val ] *)
      LoadMeta NodeId;    (* Stack: [ FromNodeId (OurNodeId); Val ] *)
      LoadPayload 0;      (* Stack: [ DestNodeId; FromNodeId; Val ] *)
      
      (* Increment and store our local Sequence ID *)
      Load mem.seq_id;    (* Stack: [ current_seq_id; DestNodeId; FromNodeId; Val ] *)
      PushConst 1;        (* Stack: [ 1; current_seq_id; ... ] *)
      Add;                (* Stack: [ new_seq_id; ... ] *)
      Store mem.seq_id;   (* RAM[seq_id] <- new_seq_id (keeps new_seq_id on stack top) *)
      
      (* Broadcast flood packet: [SeqId; DestNodeId; FromNodeId; Val] *)
      SendTo (output.tx, 4);
      Halt;
    ]
  |];

  (* --- PHASE 2: CONVERGECAST UPWARDS TO ROOT --- *)
  (* Construct Convergecast Packet: [LeaderId; TTL; DestNodeId; FromNodeId; Val] *)
  LoadPayload 1;          (* Stack: [ Val ] *)
  LoadMeta NodeId;        (* Stack: [ FromNodeId; Val ] *)
  LoadPayload 0;          (* Stack: [ DestNodeId; FromNodeId; Val ] *)
  Load mem.parent_id;     (* Stack: [ ParentId; DestNodeId; FromNodeId; Val ] *)
  
  (* Ship the packet up the tree [ParentId; ToNodeId; FromeNodeId; Val] *)
  SendTo (output.root_tx, 4);
 ]


(* =========================================================================
   ROOT_RX HANDLER
   Processes packets climbing the Spanning Tree.
   Incoming Payload: [ParentId; ToNodeId; FromNodeId; Val]
   Outgoing Upward Payload: [ParentId; ToNodeId; FromeNodeId; Val]
   ========================================================================= *)
let root_rx = [
  (* 1. Verify if we are the Root node target *)
  Load mem.parent_id;        
  NonEqPop (-1);
  
  BranchOf [|
    (* --- BRANCH 0: TRANSIT NODE (Forward packet upstream) --- *)
    [
	  LoadPayload 0;
	  LoadMeta NodeId;
	  Sub;
	  NonEqPop 0;
      BranchOf [| 
        [ Halt ]          (* Discard packet to prevent routing loops *)
      |];
      
      (* Repack and forward the convergecast packet *)
      LoadPayload 3;      (* Stack: [ Val ] *)
      LoadPayload 2;      (* Stack: [ FromNodeId; Val ] *)
      LoadPayload 1;      (* Stack: [ DestNodeId; FromNodeId; Val ] *)
      Load mem.parent_id;      (* Stack: [ ParentId; DestNodeId; FromNodeId; Val ] *)
      
      SendTo (output.root_tx, 4); (* Forward upstream *)
      Halt;
    ];
    
    (* --- BRANCH 1: WE ARE THE ROOT (Trigger downward Sequenced Flood) --- *)
	(* Incoming Payload [ParentId; ToNodeId; FromNodeId; Val] *)
    [
      (* Guard: Is the target destination of this packet the Root itself? *)
      LoadPayload 1;      (* Stack: [ DestNodeId ] *)
      LoadMeta NodeId;    (* Stack: [ OurNodeId (Root); DestNodeId ] *)
      Sub;                (* Stack: [ OurNodeId - DestNodeId ] *)
      EqPop 0;            (* Pops. If Root == DestNodeId, pushes 1 (True), else 0 (False) *)
      
      BranchOf [|
        (* Nested Branch 0: (True: Packet destined for Root) -> Deliver locally *)
        [
          LoadPayload 3;  (* Stack: [ Val ] *)
		  SendTo (output.data, 1);
          Halt;
        ];
        
        (* Initiate downward propagation *)
        [
          (* Pack parameters *)
          LoadPayload 3;  (* Stack: [ Val ] *)
          LoadPayload 2;  (* Stack: [ FromNodeId; Val ] *)
          LoadPayload 1;  (* Stack: [ DestNodeId; FromNodeId; Val ] *)
          
          (* Increment local sequence number and store *)
          Load mem.seq_id;(* Stack: [ current_seq_id; DestNodeId; FromNodeId; Val ] *)
          PushConst 1;    (* Stack: [ 1; current_seq_id; ... ] *)
          Add;            (* Stack: [ new_seq_id; ... ] *)
          Store mem.seq_id;(* RAM[seq_id] <- new_seq_id (keeps new_seq_id on stack top) *)
          
          (* Broadcast flood packet: [SeqId; DestNodeId; FromNodeId; Val] *)
          SendTo (output.tx, 4);
        ]		
      |]
    ]
  |]
]


(* =========================================================================
   RX HANDLER
   Processes downward flood packets.
   Incoming Payload: [SeqId; DestNodeId; FromNodeId; Val]
   ========================================================================= *)
let rx = [
  (* --- A. SEQUENCE NUMBER DEDUPLICATION --- *)
  PushA;                  (* Push Incoming SeqId (passed in RegA) onto stack *)
  Load mem.seq_id;        (* Stack: [ cached_seq_id; incoming_seq_id ] *)
  Sub;                    (* Stack: [ cached_seq_id - incoming_seq_id ] *)
  GtPop 0;                (* Pops. If (cached - incoming) > 0 (Old/Duplicate), pushes 1, else 0 (New) *)
  
  BranchOf [|
    (* Branch 0: (True: New message) -> Update local sequence cache and proceed *)
    [
      PushA;              (* Push incoming SeqId *)
      Store mem.seq_id;   (* RAM[seq_id] <- incoming SeqId *)
      Pop;                (* Clean up residual stack value *)
    ];
    (* Branch 1: (False: Old/Duplicate message) -> Drop packet instantly *)
    [ Halt ]
  |];

  (* --- B. DESTINATION CHECK --- *)
  LoadPayload 1;          (* Stack: [ DestNodeId ] *)
  LoadMeta NodeId;        (* Stack: [ OurNodeId; DestNodeId ] *)
  Sub;                    (* Stack: [ OurNodeId - DestNodeId ] *)
  NonEqPop 0;             (* Pops. If OurNodeId <> DestNodeId, pushes 1 (Transit), else 0 (Target) *)
  
  BranchOf [|
    (* Branch 0: TRANSIT NODE (Not equal -> Keep forwarding the flood) *)
    [
      LoadPayload 3;      (* Stack: [ Val ] *)
      LoadPayload 2;      (* Stack: [ FromNodeId; Val ] *)
      LoadPayload 1;      (* Stack: [ DestNodeId; FromNodeId; Val ] *)
      LoadPayload 0;      (* Stack: [ SeqId; DestNodeId; FromNodeId; Val ] *)
      SendTo (output.tx, 4); (* Retransmit downward *)
    ];
    
    (* Branch 1: TARGET REACHED (Equal -> Deliver packet payload to the node) *)
    [
      LoadPayload 3;      (* Stack: [ Val ] *)
	  SendTo (output.data, 1)
    ]
  |]
]

let handlers = make_handlers ~stp_init ~stp ~send ~root_rx ~rx
