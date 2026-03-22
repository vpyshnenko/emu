(* ext.ml - External events node for digital locker tests *)
open Emu

type ext_output = {
  setup_data : int;
  auth_data : int;
  clear : int;
}

type ext = {
  id : int;
  node: Node.t;
  output : ext_output;
}

let make_ext ~id : ext =
  let vm = Vm.create ~stack_capacity:30 ~max_steps:100 ~mem_size:0 in
  let b = Builder.Node.create ~state:[] ~vm ~id () in
  

  let setup_data = b.add_out_port () in      (* port 0 *)
  let auth_data = b.add_out_port () in    (* port 1 *)
  let clear = b.add_out_port () in     (* port 2 *)
  
  let output = {
    setup_data;
    auth_data;
    clear;
  } in
  
  let node = b.finalize () in
  
  {
    id = node.id;
	node;
    output;
  }
