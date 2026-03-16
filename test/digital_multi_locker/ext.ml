(* ext.ml - External events node for digital locker tests *)
open Emu

type ext_output = {
  setup_data : int;
  auth_data : int;
  setup_reset : int;
  auth_reset : int;
  clear : int;
}

type ext = {
  id : int;
  node: Node.t;
  output : ext_output;
}

let make_ext () : ext =
  let vm = Vm.create ~stack_capacity:30 ~max_steps:100 ~mem_size:0 in
  let b = Builder.Node.create ~state:[] ~vm in
  
  let output = {
      setup_data = b.add_out_port ();
      auth_data = b.add_out_port ();
      setup_reset = b.add_out_port ();
      auth_reset = b.add_out_port ();
      clear = b.add_out_port ();
  } in
	
  let node = b.finalize () in
  
  {
    id = node.id;
	node;
    output;
  }
