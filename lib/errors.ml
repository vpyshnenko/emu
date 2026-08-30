(* Emu_Vm_Exec_Error (VmStep, Instr, msg) *)
exception Emu_Vm_Exec_Error of int * Instructions.instr * string


let handle_delivery_error dst_id in_port sender_id payload exn =
  match exn with
	 | Emu_Vm_Exec_Error (vm_step, instr, msg) -> 
	     let ctx = Context.build ~node_id:dst_id ~in_port ~sender_id ~payload ~vm_step ~instr () in
		 Context.print ctx;
		 failwith msg
	 | Failure msg -> 
	     let ctx = Context.build ~node_id:dst_id ~in_port ~sender_id ~payload () in
		 Context.print ctx;
		 failwith msg
     (* Case 3: Unexpected system exceptions (e.g., Division_by_zero, Out_of_bounds) *)
     | exn ->
         let ctx = Context.build
           ~node_id:dst_id
           ~in_port
           ~sender_id
           ~payload
           ()
         in
		 Context.print ctx;
		 failwith (Printexc.to_string exn)
