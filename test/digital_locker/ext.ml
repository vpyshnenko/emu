(* ext.ml - External events node for digital locker tests *)


type ext_output = {
  setup_digit : int;
  auth_digit : int;
  payload : int;
  reset_setup : int;
  reset_auth : int;
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
      setup_digit = b.add_out_port ();
      auth_digit = b.add_out_port ();
      payload = b.add_out_port ();
      reset_setup = b.add_out_port ();
      reset_auth = b.add_out_port ();
      clear = b.add_out_port ();
  } in
	
  let node = b.finalize () in
  
  {
    id = node.id;
	node;
    output;
  }
