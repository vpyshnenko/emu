(* net.ml - Network construction for hierarchical digital locker *)

type t = {
  net : Emu.Net.t;
  ext : Ext.ext;
  routers : Router.router array array;  (* [layer][branch] *)
  leaves : Leaf.leaf array;              (* Final leaves at depth L *)
  observer : Observer.observer;
  payload : Payload.payload;
  unlocker : Unlocker.unlocker;
}

let make_net ~n ~l () : t =
  if l < 1 then failwith "Password length must be at least 1";
  
  let ext = Ext.make_ext () in
  
  (* Create hierarchical routers *)
  let routers = Array.make l [||] in
  
  (* Layer 0 (root layer) - just one router *)
  routers.(0) <- [| Router.make_root_router ~n |];
  
  (* Layers 1 to l-1 - n^(layer) routers *)
  for layer = 1 to l-1 do
    let count = int_of_float (float n ** float layer) in
    routers.(layer) <- Array.init count (fun _ -> Router.make_router ~n)
  done;
  
  (* Create leaves - n^l leaves at the bottom *)
  let leaf_count = int_of_float (float n ** float l) in
  let leaves = Array.init leaf_count (fun _ -> Leaf.make_leaf ()) in
  
  let observer = Observer.make_observer () in
  let payload = Payload.make_payload () in
  let unlocker = Unlocker.make_unlocker ~n:leaf_count () in  (* One input per leaf *)
  
  (* Create network builder *)
  let nb, ( --> ) = Emu.Builder.Net.create () in
  
  (* Add external node *)
  let idExt = nb.add_node ext.node in
  
  (* Add all routers *)
  let router_ids = Array.map (Array.map (fun (r: Router.router)  -> nb.add_node r.node)) routers in
  
  (* Add all leaves *)
  let leaf_ids = Array.map (fun (lf: Leaf.leaf) -> nb.add_node lf.node) leaves in
  
  (* Add observer, payload, unlocker *)
  let idObserver = nb.add_node observer.node in
  let idPayload = nb.add_node payload.node in
  let idUnlocker = nb.add_node unlocker.node in
  
  (* Connect external to root router *)
  (idExt, ext.output.setup_reset) --> (router_ids.(0).(0), routers.(0).(0).input.setup_reset);
  (idExt, ext.output.auth_reset) --> (router_ids.(0).(0), routers.(0).(0).input.auth_reset);
  (idExt, ext.output.setup) --> (router_ids.(0).(0), routers.(0).(0).input.setup);
  (idExt, ext.output.auth) --> (router_ids.(0).(0), routers.(0).(0).input.auth);
  
  (* Connect external to payload *)
  (idExt, ext.output.payload) --> (idPayload, payload.input.set);
  (idExt, ext.output.clear) --> (idPayload, payload.input.clear);
  
  (* Connect router layers *)
  for layer = 0 to l-2 do
    let current_layer = routers.(layer) in
    let next_layer = routers.(layer+1) in
    let next_layer_size = Array.length next_layer in
    
    (* Each router in current layer connects to n routers in next layer *)
    for i = 0 to Array.length current_layer - 1 do
      for digit = 0 to n-1 do
        let target_idx = i * n + digit in
        if target_idx < next_layer_size then
          (router_ids.(layer).(i), current_layer.(i).output.setup.(digit)) --> 
            (router_ids.(layer+1).(target_idx), next_layer.(target_idx).input.setup);
          
          (router_ids.(layer).(i), current_layer.(i).output.auth.(digit)) --> 
            (router_ids.(layer+1).(target_idx), next_layer.(target_idx).input.auth);
          
          (idExt, ext.output.setup_reset) --> 
            (router_ids.(layer+1).(target_idx), next_layer.(target_idx).input.setup_reset)
      done
    done
  done;
  
  (* Connect last layer of routers to leaves *)
  let last_layer = routers.(l-1) in
  for i = 0 to Array.length last_layer - 1 do
    for digit = 0 to n-1 do
      let leaf_idx = i * n + digit in
      if leaf_idx < Array.length leaves then (
        (router_ids.(l-1).(i), last_layer.(i).output.setup.(digit)) --> 
          (leaf_ids.(leaf_idx), leaves.(leaf_idx).input.setup);
        
        (router_ids.(l-1).(i), last_layer.(i).output.auth.(digit)) --> 
          (leaf_ids.(leaf_idx), leaves.(leaf_idx).input.auth);
        
        (idExt, ext.output.setup_reset) --> 
          (leaf_ids.(leaf_idx), leaves.(leaf_idx).input.reset)
      )
    done
  done;
  
  (* Connect leaves to unlocker and observer *)
  for i = 0 to Array.length leaves - 1 do
    (leaf_ids.(i), leaves.(i).output.auth_ok) --> (idUnlocker, unlocker.input.auth_ok.(i));
    (leaf_ids.(i), leaves.(i).output.setup_ok) --> (idObserver, observer.input.setup_ok);
    (leaf_ids.(i), leaves.(i).output.auth_fail) --> (idObserver, observer.input.auth_fail)
  done;
  
  (* Connect unlocker to payload and observer *)
  (idUnlocker, unlocker.output.auth_ok) --> (idPayload, payload.input.unlock);
  (idUnlocker, unlocker.output.auth_ok) --> (idObserver, observer.input.auth_ok);
  
  (* Finalize network *)
  let net = nb.finalize () in
  
  {
    net;
    ext;
    routers;
    leaves;
    observer;
    payload;
    unlocker;
  }