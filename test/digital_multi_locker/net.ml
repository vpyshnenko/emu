(* net.ml - Network construction for hierarchical digital locker *)

type t = {
  net : Emu.Net.t;
  ext : Ext.ext;
  routers : Router.router array array;  (* [layer][branch] *)
  leaves : Leaf.leaf array;              (* Final leaves at depth L *)
  observer : Observer.observer;
}


let make_id_generator ~init =
  let counter = ref init in
  fun () ->
    let id = !counter in
    incr counter;
    id


let make_net ~n ~l () : t =

  let next_id = make_id_generator ~init:0 in
  
  if l < 1 then failwith "Password length must be at least 1";
  
  let ext = Ext.make_ext ~id:(next_id ()) in
  
  (* Create hierarchical routers *)
  let routers = Array.make l [||] in
  
  (* Layer 0 (root layer) - just one router *)
  routers.(0) <- [| Router.make_root_router ~n ~l ~id:(next_id ()) |];
  
  let make_router = Router.make_router_gen ~n in
  (* Layers 1 to l-1 - n^(layer) routers *)
  for layer = 1 to l-1 do
    let count = int_of_float (float n ** float layer) in
    routers.(layer) <- Array.init count (fun _ -> make_router ~id:(next_id ()))
  done;
  
  (* Create leaves - n^l leaves at the bottom *)
  let leaf_count = int_of_float (float n ** float l) in
  let leaves = Array.init leaf_count (fun _ -> Leaf.make_leaf ~id:(next_id ())) in
  
  let observer = Observer.make_observer ~id:(next_id ()) in
  
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
  
  (* Add observer*)
  nb.add_node observer.node;
  
  let root_router = routers.(0).(0) in
  
  
  (* External connections *)
  (ext.id, ext.output.setup_data) --> (root_router.id, root_router.input.setup_data);
  (ext.id, ext.output.auth_data) --> (root_router.id, root_router.input.auth_data);
      
  
  (* Connect all routers *)
  Array.iteri (fun layer current_layer ->
    Array.iteri (fun i (router: Router.router) ->
      let router_id = routers.(layer).(i).id in
      
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
            (routers.(layer+1).(target_idx).id, next_layer.(target_idx).input.setup_data);
          
          (router_id, router.output.auth.(digit)) --> 
            (routers.(layer+1).(target_idx).id, next_layer.(target_idx).input.auth_data)
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
        
        (ext.id, ext.output.clear) --> 
          (leaves.(leaf_idx).id, leaves.(leaf_idx).input.reset)
      )
    done
  done;
  
  (* Connect leaves to observer *)
  for i = 0 to Array.length leaves - 1 do
    (leaves.(i).id, leaves.(i).output.value) --> (observer.id, observer.input.value);
    (leaves.(i).id, leaves.(i).output.setup_ok) --> (observer.id, observer.input.setup_ok);
    (leaves.(i).id, leaves.(i).output.auth_fail) --> (observer.id, observer.input.auth_fail)
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