(* net.ml*)

type t = {
  net : Emu.Net.t;
  ext : Ext.t;
  routers : Router.t array array;  (* [layer][router] *)
  sink : Sink.t;
}


let make_id_generator ~init =
  let counter = ref init in
  fun () ->
    let id = !counter in
    incr counter;
    id


let make_net ~l () : t =

  let next_id = make_id_generator ~init:0 in
  
  if l < 2 then failwith "Expected at least 2 layers";
    
  
  (* Create network builder *)
  let nb, ( --> ) = Emu.Builder.Net.create () in
  
  let connect_sink (r: Router.t) (sink: Sink.t) = 
    (r.id, r.output.out) --> (sink.id, sink.input.data)
  in

  let connect_overflow (r: Router.t) (sink: Sink.t) = 
    (r.id, r.output.data_lt) --> (sink.id, sink.input.overflow);
    (r.id, r.output.data_gt) --> (sink.id, sink.input.overflow)
  in
  
  let connect_lt (a: Router.t)  (b: Router.t) = 
    (a.id, a.output.data_lt) --> (b.id, b.input.data);
    (a.id, a.output.reset) --> (b.id, b.input.reset)
  in
  	
  let connect_gt (a: Router.t) (b: Router.t) = 
    (a.id, a.output.data_gt) --> (b.id, b.input.data);
    (a.id, a.output.reset) --> (b.id, b.input.reset)
  in
  
  (* Add external node *)
  let ext = Ext.make ~id:(next_id ()) in
  nb.add_node ext.node;
  
  let sink = Sink.make ~l ~id:(next_id ()) in
  nb.add_node sink.node;
  
  
  (* Create hierarchical routers *)
  let routers = Array.make l [||] in
  
  (* Layers 0 to l-1 routers *)
  for layer = 0 to l-1 do
	let count = 1 lsl layer in (* use bit shifting here: 2^layer *)
    routers.(layer) <- Array.init count (fun _ -> Router.make ~id:(next_id ()))
  done;
  
  let last_layer_idx = Array.length routers - 1 in
  (* Add all routers *)
  Array.iteri (fun layer_idx layer ->
    Array.iter (fun (r : Router.t) ->
      nb.add_node r.node;
	  connect_sink r sink;
	  if (layer_idx == last_layer_idx) then
	    connect_overflow r sink;
    ) layer	
  ) routers;

  let root_router = routers.(0).(0) in
    
  (* External connections *)
  (ext.id, ext.output.data) --> (root_router.id, root_router.input.data);
  (ext.id, ext.output.reset) --> (root_router.id, root_router.input.reset);
  (ext.id, ext.output.reset) --> (sink.id, sink.input.reset);
  
  (* Connect all routers *)
  Array.iteri (fun layer current_layer ->
    Array.iteri (fun i (router: Router.t) ->
	  let next_layer = routers.(layer+1) in
	  let child_idx = 2*i in
      let router_lt = next_layer.(child_idx) in
	  let router_gt = next_layer.(child_idx + 1) in
	   connect_lt router router_lt;
	   connect_gt router router_gt
    ) current_layer
  ) (Array.sub routers 0 (Array.length routers - 1));
  
  (* Finalize network *)
  let net = nb.finalize () in
  
  {
    net;
    ext;
	routers;
    sink;
  }