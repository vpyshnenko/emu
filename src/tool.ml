(* tool.ml - Reusable network comparison utilities *)
module IntMap = Map.Make(Int)

type state_diff = {
  changed : (State.t * State.t) IntMap.t;  (* nodes with different states *)
  only_in_net1 : State.t IntMap.t;          (* nodes only in net1 *)
  only_in_net2 : State.t IntMap.t;          (* nodes only in net2 *)
}

let distinct_states (net1 : Net.t) (net2 : Net.t) : state_diff =
  let changed = ref IntMap.empty in
  let only_in_net1 = ref IntMap.empty in
  let only_in_net2 = ref IntMap.empty in
  
  (* Helper to get node state *)
  let node_state node = node.Node.state in
  
  (* Check nodes in net1 *)
  IntMap.iter
    (fun node_id node1 ->
      match IntMap.find_opt node_id net2.Net.nodes with
      | None ->
          only_in_net1 := IntMap.add node_id (node_state node1) !only_in_net1
      | Some node2 ->
          if node_state node1 <> node_state node2 then
            changed := IntMap.add node_id (node_state node1, node_state node2) !changed
    )
    net1.Net.nodes;
  
  (* Check nodes only in net2 *)
  IntMap.iter
    (fun node_id node2 ->
      if not (IntMap.mem node_id net1.Net.nodes) then
        only_in_net2 := IntMap.add node_id (node_state node2) !only_in_net2
    )
    net2.Net.nodes;
  
  { changed = !changed; only_in_net1 = !only_in_net1; only_in_net2 = !only_in_net2 }

let are_identical net1 net2 =
  let diff = distinct_states net1 net2 in
  IntMap.is_empty diff.changed &&
  IntMap.is_empty diff.only_in_net1 &&
  IntMap.is_empty diff.only_in_net2

let print_state_diff (diff : state_diff) : unit =
  let pp_state state = 
    "[" ^ (String.concat "; " (List.map string_of_int state)) ^ "]"
  in
  
  if IntMap.is_empty diff.changed &&
     IntMap.is_empty diff.only_in_net1 &&
     IntMap.is_empty diff.only_in_net2 then
    Printf.printf "Networks are identical\n"
  else begin
    (* Print changed nodes *)
    if not (IntMap.is_empty diff.changed) then
      Printf.printf "\n=== Changed nodes (%d) ===\n" (IntMap.cardinal diff.changed);
    IntMap.iter
      (fun node_id (state1, state2) ->
        Printf.printf "Node %d: %s → %s\n" node_id (pp_state state1) (pp_state state2)
      )
      diff.changed;
    
    (* Print nodes only in net1 *)
    if not (IntMap.is_empty diff.only_in_net1) then
      Printf.printf "\n=== Nodes only in net1 (%d) ===\n" (IntMap.cardinal diff.only_in_net1);
    IntMap.iter
      (fun node_id state ->
        Printf.printf "Node %d: state = %s\n" node_id (pp_state state)
      )
      diff.only_in_net1;
    
    (* Print nodes only in net2 *)
    if not (IntMap.is_empty diff.only_in_net2) then
      Printf.printf "\n=== Nodes only in net2 (%d) ===\n" (IntMap.cardinal diff.only_in_net2);
    IntMap.iter
      (fun node_id state ->
        Printf.printf "Node %d: state = %s\n" node_id (pp_state state)
      )
      diff.only_in_net2;
  end

(* Helper to get specific node state difference *)
let get_node_diff node_id diff =
  match IntMap.find_opt node_id diff.changed with
  | Some (before, after) -> Some (`Changed (before, after))
  | None ->
      match IntMap.find_opt node_id diff.only_in_net1 with
      | Some state -> Some (`OnlyInNet1 state)
      | None ->
          match IntMap.find_opt node_id diff.only_in_net2 with
          | Some state -> Some (`OnlyInNet2 state)
          | None -> None

(* Helper to count total differences *)
let total_differences diff =
  IntMap.cardinal diff.changed +
  IntMap.cardinal diff.only_in_net1 +
  IntMap.cardinal diff.only_in_net2