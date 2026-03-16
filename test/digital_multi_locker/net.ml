(* net.ml - Network construction for hierarchical digital locker *)

type t = {
  net : Emu.Net.t;
  ext : Ext.ext;
  routers : Router.router array array;  (* [layer][branch] *)
  leaves : Leaf.leaf array;              (* Final leaves at depth L *)
  observer : Observer.observer;
}

let make_net ~n ~l () : t =
  if l < 1 then failwith "Password length must be at least 1";
  
  let ext = Ext.make_ext () in
  
  (* Create hierarchical routers *)
  let routers = Array.make l [||] in
  
  (* Layer 0 (root layer) - just one router *)
  routers.(0) <- [| Router.make_router ~n |];
  
  (* Layers 1 to l-1 - n^(layer) routers *)
  for layer = 1 to l-1 do
    let count = int_of_float (float n ** float layer) in
    routers.(layer) <- Array.init count (fun _ -> Router.make_router ~n)
  done;
  
  (* Create leaves - n^l leaves at the bottom *)
  let leaf_count = int_of_float (float n ** float l) in
  let leaves = Array.init leaf_count (fun _ -> Leaf.make_leaf ()) in
  
  let observer = Observer.make_observer () in
  
  (* Create network builder *)
  let nb, ( --> ) = Emu.Builder.Net.create () in
  
  (* Add external node *)
  let idExt = nb.add_node ext.node in
  
  (* Add all routers *)
  let router_ids = Array.map (Array.map (fun (r: Router.router)  -> nb.add_node r.node)) routers in
  
  (* Add all leaves *)
  let leaf_ids = Array.map (fun (lf: Leaf.leaf) -> nb.add_node lf.node) leaves in
  
  (* Add observer*)
  let idObserver = nb.add_node observer.node in
  
  let root_router = routers.(0).(0) in
  
  
       (* External connections *)
  (idExt, ext.output.setup_reset) --> (root_router.id, root_router.input.setup_reset);
  (idExt, ext.output.auth_reset) --> (root_router.id, root_router.input.auth_reset);
  (idExt, ext.output.setup_data) --> (root_router.id, root_router.input.setup_data);
  (idExt, ext.output.auth_data) --> (root_router.id, root_router.input.auth_data);
      
  
  (* Connect all routers *)
  Array.iteri (fun layer current_layer ->
    Array.iteri (fun i (router: Router.router) ->
      let router_id = router_ids.(layer).(i) in
      
      (* External connections *)
      (idExt, ext.output.setup_reset) --> (router_id, router.input.setup_reset);
      (idExt, ext.output.auth_reset) --> (router_id, router.input.auth_reset);
      
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
            (router_ids.(layer+1).(target_idx), next_layer.(target_idx).input.setup_data);
          
          (router_id, router.output.auth.(digit)) --> 
            (router_ids.(layer+1).(target_idx), next_layer.(target_idx).input.auth_data)
        ) (Array.init n Fun.id)
    ) current_layer
  ) routers;
  
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
        
        (idExt, ext.output.clear) --> 
          (leaf_ids.(leaf_idx), leaves.(leaf_idx).input.reset)
      )
    done
  done;
  
  (* Connect leaves to observer *)
  for i = 0 to Array.length leaves - 1 do
    (leaf_ids.(i), leaves.(i).output.value) --> (idObserver, observer.input.value);
    (leaf_ids.(i), leaves.(i).output.setup_ok) --> (idObserver, observer.input.setup_ok);
    (leaf_ids.(i), leaves.(i).output.auth_fail) --> (idObserver, observer.input.auth_fail)
  done;
  
  (* Finalize network *)
  let net = nb.finalize () in
  
  {
    net;
    ext;
    routers;
    leaves;
    observer;
  }