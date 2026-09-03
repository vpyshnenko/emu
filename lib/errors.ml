(* Emu_Vm_Exec_Error (VmStep, Instr, msg) *)
exception Emu_Vm_Exec_Error of int * Instructions.instr * string


let handle_delivery_error ava_step dst_id in_port sender_id out_port payload exn =
  match exn with
	 | Emu_Vm_Exec_Error (vm_step, instr, msg) -> 
	     let ctx = Context.build ~ava_step ~node_id:dst_id ~in_port ~sender_id ~out_port ~payload ~vm_step ~instr () in
		 Context.print ctx msg;
		 failwith msg
	 | Failure msg -> 
	     let ctx = Context.build ~ava_step ~node_id:dst_id ~in_port ~sender_id ~out_port ~payload () in
		 Context.print ctx msg;
		 failwith msg
     (* Case 3: Unexpected system exceptions (e.g., Division_by_zero, Out_of_bounds) *)
     | exn ->
	     let msg = Printexc.to_string exn in
         let ctx = Context.build
		   ~ava_step 
           ~node_id:dst_id
           ~in_port
           ~sender_id
		   ~out_port
           ~payload
           ()
         in
		 Context.print ctx msg;
		 failwith msg
