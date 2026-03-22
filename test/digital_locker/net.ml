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
  nb.add_node ext.node;
  
  (* Add all routers *)
  Array.iter (fun layer ->
    Array.iter (fun (r : Router.router) ->
      nb.add_node r.node
    ) layer
  ) routers;

  (* Add all leaves *)
  Array.iter (fun (lf: Leaf.leaf) -> nb.add_node lf.node) leaves;
  
  (* Add observer, payload, unlocker *)
  nb.add_node observer.node;
  nb.add_node payload.node;
  nb.add_node unlocker.node;
  
  
  (* Connect external to payload *)
  (ext.id, ext.output.payload) --> (payload.id, payload.input.set);
  (ext.id, ext.output.clear) --> (payload.id, payload.input.clear);
  
  (* Connect all routers *)
  Array.iteri (fun layer current_layer ->
    Array.iteri (fun i (router: Router.router) ->
      let router_id = routers.(layer).(i).id in
      
      (* External connections *)
      (ext.id, ext.output.setup_reset) --> (router_id, router.input.setup_reset);
      (ext.id, ext.output.auth_reset) --> (router_id, router.input.auth_reset);
      (ext.id, ext.output.setup_data) --> (router_id, router.input.setup_data);
      (ext.id, ext.output.auth_data) --> (router_id, router.input.auth_data);
      
      (* Connect to children *)
      if layer < l-1 then
        let next_layer = routers.(layer+1) in
        Array.iteri (fun digit _ ->
          let target_idx = i * n + digit in
		  if target_idx >= Array.length next_layer then
            failwith (Printf.sprintf 
              "Invalid connection: layer %d router %d digit %d -> target %d (max %d)"
              layer i digit target_idx (Array.length next_layer - 1));
          (router_id, router.output.setup.(digit)) --> 
            (routers.(layer+1).(target_idx).id, next_layer.(target_idx).input.setup_token);
          
          (router_id, router.output.auth.(digit)) --> 
            (routers.(layer+1).(target_idx).id, next_layer.(target_idx).input.auth_token)
        ) (Array.init n Fun.id)
    ) current_layer
  ) routers;
  
  (* Connect last layer of routers to leaves *)
  let last_layer = routers.(l-1) in
  for i = 0 to Array.length last_layer - 1 do
    for digit = 0 to n-1 do
      let leaf_idx = i * n + digit in
      if leaf_idx < Array.length leaves then (
        (routers.(l-1).(i).id, last_layer.(i).output.setup.(digit)) --> 
          (leaves.(leaf_idx).id, leaves.(leaf_idx).input.setup);
        
        (routers.(l-1).(i).id, last_layer.(i).output.auth.(digit)) --> 
          (leaves.(leaf_idx).id, leaves.(leaf_idx).input.auth);
        
        (ext.id, ext.output.setup_reset) --> 
          (leaves.(leaf_idx).id, leaves.(leaf_idx).input.reset)
      )
    done
  done;
  
  (* Connect leaves to unlocker and observer *)
  for i = 0 to Array.length leaves - 1 do
    (leaves.(i).id, leaves.(i).output.auth_ok) --> (unlocker.id, unlocker.input.auth_ok.(i));
    (leaves.(i).id, leaves.(i).output.setup_ok) --> (observer.id, observer.input.setup_ok);
    (leaves.(i).id, leaves.(i).output.auth_fail) --> (observer.id, observer.input.auth_fail)
  done;
  
  (* Connect unlocker to payload and observer *)
  (unlocker.id, unlocker.output.auth_ok) --> (payload.id, payload.input.unlock);
  (unlocker.id, unlocker.output.auth_ok) --> (observer.id, observer.input.auth_ok);
  
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