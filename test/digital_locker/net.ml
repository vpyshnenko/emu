(* net.ml - Network construction for digital locker tests *)

type t = {
  net : Emu.Net.t;
  ext : Ext.ext;
  root_router : Router.router;
  leaves : Leaf.leaf array;  (* Array for O(1) access by index *)
  observer : Observer.observer;
  payload : Payload.payload;
  unlocker : Unlocker.unlocker; 
}

let make_net ~n () : t =
  let ext = Ext.make_ext () in
  let root_router = Router.make_root_router ~n in
  
  (* Create n leaves as array *)
  let leaves = Array.init n (fun _ -> Leaf.make_leaf ()) in
  let observer = Observer.make_observer () in  
  let payload = Payload.make_payload () in
  let unlocker = Unlocker.make_unlocker ~n () in
  
  (* Create network builder *)
  let nb, ( --> ) = Emu.Builder.Net.create () in
  
  (* Add nodes to network *)
  let idExt = nb.add_node ext.node in
  let idRouter = nb.add_node root_router.node in
  let idLeaves = Array.map (fun (lf: Leaf.leaf) -> nb.add_node lf.node) leaves in
  let idObserver = nb.add_node observer.node in
  let idPayload = nb.add_node payload.node in
  let idUnlocker = nb.add_node unlocker.node in
  
    (* External connections to payload cell *)
  (idExt, ext.output.payload) --> (idPayload, payload.input.set);
  (idExt, ext.output.clear) --> (idPayload, payload.input.clear);
  
  (* Connect external to router *)
  (idExt, ext.output.setup_reset) --> (idRouter, root_router.input.setup_reset);
  (idExt, ext.output.auth_reset) --> (idRouter, root_router.input.auth_reset);
  (idExt, ext.output.setup) --> (idRouter, root_router.input.setup);
  (idExt, ext.output.auth) --> (idRouter, root_router.input.auth);
  
  (* Connect router to each leaf *)
  for i = 0 to n-1 do
    (idRouter, root_router.output.setup.(i)) --> (idLeaves.(i), leaves.(i).input.setup);
    (idRouter, root_router.output.auth.(i)) --> (idLeaves.(i), leaves.(i).input.auth);
    (idExt, ext.output.setup_reset) --> (idLeaves.(i), leaves.(i).input.reset)  (* Optional: reset leaves *)
  done;
  
  (* Leaf auth_ok all go to unlocker *)
  for i = 0 to n-1 do
    (idLeaves.(i), leaves.(i).output.auth_ok) --> (idUnlocker, unlocker.input.auth_ok.(i))
  done;
  
  (* Unlocker fans out to both payload and observer *)
  (idUnlocker, unlocker.output.auth_ok) --> (idPayload, payload.input.unlock);
  (idUnlocker, unlocker.output.auth_ok) --> (idObserver, observer.input.auth_ok);
  
    (* Leaf to observer connections *)
  for i = 0 to n-1 do
    (idLeaves.(i), leaves.(i).output.setup_ok) --> (idObserver, observer.input.setup_ok);
    (idLeaves.(i), leaves.(i).output.auth_fail) --> (idObserver, observer.input.auth_fail);
  done;
  
  (* Finalize network *)
  let net = nb.finalize () in
  
  {
    net;
    ext;
    root_router;
    leaves;
	observer;
	payload; 
	unlocker;
  }

(* Optional: Create initial snapshot for testing *)
let create_initial_snapshot net =
  Emu.Runtime.create ~lifespan:1000 net