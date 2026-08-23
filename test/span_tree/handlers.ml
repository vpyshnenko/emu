(* handlers.ml *)
open Emu.Instructions
open Layout

(* =========================================================================
   1. STP INIT HANDLER: Triggered on the Root node to initiate STP.
   ========================================================================= *)
let stp_init = [
  (* Set Parent Node ID to -1 (indicates "I am the Root" or "No Parent") *)
  PushConst (-1);
  Store mem.parent_node_id;                 (* RAM[parent_node_id] <- -1 *)
  Pop;                                      (* Clean up the stack *)
  
  (* Root's distance to itself is 0 *)
  PushConst 0;
  Store mem.distance;                       (* RAM[distance] <- 0 *)
  
  (* Prepare to broadcast our distance to neighbor nodes *)
  PopA;                                     (* Pop the 0 into Register A *)
  EmitTo output.stp;                        (* Broadcast the value in RegA (0) via STP output port *)
]

(* =========================================================================
   2. STP HANDLER: Processes incoming distance advertisements from neighbors.
   ========================================================================= *)
let stp = [
  (* Calculate proposed distance: incoming distance (passed in Register A) + 1 *)
  PushA;                                    (* Push received distance from RegA onto the stack *)
  PushConst 1;
  Add;                                      (* Stack: [ proposed_distance ] *)
  
  (* Compare proposed distance with our current stored distance *)
  Dup;                                      (* Stack: [ proposed_distance; proposed_distance ] *)
  Load mem.distance;                        (* Stack: [ current_distance; proposed_distance; proposed_distance ] *)
  Sub;                                      (* Stack: [ (current_distance - proposed_distance); proposed_distance ] *)
  LtPop 0;                                  (* Pops comparison result. If (current - proposed) > 0 (meaning proposed < current), pushes 1 (True), else 0 *)
  
  (* If proposed_distance is smaller, update our routing state *)
  BranchOf [|
    (* --- UPDATE ROUTING STATE BRANCH --- *)
    [
      (* Update parent to the node that advertised this shorter path *)
      LoadMeta SenderNodeId;                (* Load the ID of the packet sender *)
      Store mem.parent_node_id;             (* RAM[parent_node_id] <- sender_id *)
      Pop;                                  (* Clean up stack *)
      
      (* Update our stored distance to the new, shorter distance *)
      Store mem.distance;                   (* RAM[distance] <- proposed_distance *)
      
      (* Propagate the updated distance down the tree *)
      PeekA;                                (* Load the new distance into Register A without removing it from stack *)
      EmitTo output.stp;                    (* Broadcast our new distance to our neighbors *)
    ];
  |];
  Pop;                                      (* Clean up remaining proposed_distance from stack if update branch didn't fire *)
]

(* =========================================================================
   3. COUNT INIT HANDLER: Initiates the counting phase from the Root.
   ========================================================================= *)
let count_init = [
  (* Guard check: Prevent multiple counts if a node receives duplicate count_init messages *)
  Load mem.count;                           (* Load current local count *)
  GtPop 0;                                  (* If count > 0, push True (1), else False (0) *)
  BranchOf [|
    [ Halt ]                                (* Already initialized! Stop execution *)
  |];
  
  (* Mark this node as counted (local count = 1) aka guard flag *)
  PushConst 1;
  Store mem.count;                          (* RAM[count] <- 1 *)
  Pop;
  
  (* Prepare counting report payload: [parent_node_id, my_node_id] *)
  LoadMeta NodeId;                          (* Push our own node ID *)
  Load mem.parent_node_id;                  (* Push our parent's ID (this sits on top of the stack) *)
  SendTo (output.count, 2);                 (* Send a 2-word packet [parent_id, own_id] to parent *)
  
  (* Propagate the count initialization trigger down to our children *)
  PushConst 1;
  PopA;                                     (* Put active trigger status in Register A *)
  EmitTo output.count_init;                 (* Propagate down through count_init port *)
]

(* =========================================================================
   4. COUNT HANDLER: Processes incoming reports from children/sub-trees.
   ========================================================================= *)
let count = [
  (* Security check: Is this count report actually addressed to us? *)
  LoadPayload 0;                            (* Payload[0] holds the target parent ID of the report *)
  LoadMeta NodeId;                          (* Load our own node ID *)
  Sub;
  NonEqPop 0;                               (* If TargetParentID != OwnNodeID, push True (1) *)
  BranchOf [|
    [ Halt ]                                (* Packet was meant for another node. Discard and halt *)
  |];
  
  (* Check if we are the Root node (Root has parent_node_id = -1) *)
  Load mem.parent_node_id;
  EqPop (-1);                               (* If parent_node_id == -1, push True (1) *)
  BranchOf [|
    (* --- CASE A: WE ARE THE ROOT NODE --- *)
    [ 
      (* Increment total network node count *)
      Load mem.count;
      PushConst 1;
      Add;
      Store mem.count;                      (* RAM[count] <- RAM[count] + 1 *)
      Pop;
      
      (* Keep track of the highest Node ID in the network *)
      LoadPayload 1;                        (* Payload[1] contains the ID of the reporting node *)
      Load mem.max_node_id;                 (* Load current known maximum ID *)
      Sub;
      GtPop 0;                              (* If reported_id > current_max, push True (1) *)
      BranchOf [| 
        [ 
          LoadPayload 1; 
          Store mem.max_node_id;            (* RAM[max_node_id] <- reported_id *)
          Pop; 
        ]
      |];
    ];
    (* --- CASE B: WE ARE A TRANSIT/MIDDLE NODE --- *)
    [ 
      (* Forward the reported node's ID up to our parent *)
      LoadPayload 1;                        (* Payload[1] holds the reporting node's ID *)
      Load mem.parent_node_id;              (* Load our parent's ID to address the packet *)
      SendTo (output.count, 2);             (* Forward [parent_id, reported_id] to our parent *)
    ]
  |];
]

(* =========================================================================
   5. BINDING HANDLERS
   ========================================================================= *)
let handlers = make_handlers ~stp_init ~stp ~count_init ~count