(* net.ml - Network construction for digital locker tests *)

module EmuNet = Net

type t = {
  net : EmuNet.t;
  ext : Ext.ext;
  root_router : Router.router;
}

let make_net () : t =
  let vm = Vm.create ~stack_capacity:30 ~max_steps:100 ~mem_size:0 in
  
  (* Create nodes first - they need their own Vm instances *)
  let ext = Ext.make_ext () in
  let root_router = Router.make_root_router ~n:2 () in
  
  (* Create network builder *)
  let nb, ( --> ) = EmuNet.create () in
  
  (* Add nodes to network *)
  let idExt = nb.add_node ext.Ext.node in
  let idRouter = nb.add_node root_router.Router.node in
  
  (* Connect nodes *)
  (idExt, ext.Ext.output.reset_setup) --> (idRouter, root_router.Router.input.reset_setup);
  (idExt, ext.Ext.output.reset_auth) --> (idRouter, root_router.Router.input.reset_auth);
  
  (* Add more connections as needed *)
  (* (idExt, ext.output.setup_digit) --> (idRouter, root_router.input.setup_digit); *)
  (* (idExt, ext.output.auth_digit) --> (idRouter, root_router.input.auth_digit); *)
  
  (* Finalize network *)
  let net = nb.finalize () in
  
  {
    net;
    ext;
    root_router;
  }

(* Optional: Create initial snapshot for testing *)
let create_initial_snapshot net =
  Runtime.create ~lifespan:1000 net