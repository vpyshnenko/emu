open OUnit2
open Instructions

let pp_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"

(* ------------------------------------------------------------ *)
(* Digital Vault (B=3, L=3)                                      *)
(* Password = address sequence                                   *)
(* ------------------------------------------------------------ *)

let test_digital_vault _ctx =
  (* Shared VM defaults *)
  let vm = Vm.create ~stack_capacity:30 ~max_steps:100 ~mem_size:2 in


 
  
    let bRouter = Builder.Node.create ~state:[1;1] ~vm in
    
    (* Ports *) (*
    let inSetupToken =
      bRouter.add_handler [
          PushConst 1;
          Store 0;
      ]
    in
    
    let inAuthToken =
      bRouter.add_handler [
          PushConst 1;
          Store 1;
      ]
    in
    *)
    let inSetupDigit =
      bRouter.add_handler [
        Load 0;              
		Eq 1;               (* has_setup_token *)
        BranchOf [|
          [
            PushA;           (* push digit *)
            Emit;            (* emit to port digit *)
            PushConst 0; Store 0;   (* clear token *)
          ];
        |];
    ]

    in
    
    let inAuthDigit =
      bRouter.add_handler [
	    Load 1;
		Eq 1;
		BranchOf [|
          [
            PushA;
            PushConst 2;
            Add;
            Emit;
            PushConst 0; Store 1;   (* clear token *)
          ];
        |];
   
		
      ]
    in
    
    let inResetSetup =
      bRouter.add_handler [
        PushConst 0;
 	    Store 0;
      ]
    in
	
    let inResetAuth =
      bRouter.add_handler [
        (* PushConst 0; *)
        PushConst 1;
 	    Store 1;
      ]
    in
    
    let out_setup0 = bRouter.add_out_port () in
    let out_setup1 = bRouter.add_out_port () in
    
    let out_auth0 = bRouter.add_out_port () in
    let out_auth1 = bRouter.add_out_port () in
    
    let nodeRouter = bRouter.finalize () in
	

  
  
  
  (* ======= Leaf Node============*)
  let makeLeaf () = 
    let bLeaf = Builder.Node.create ~state:[0] ~vm in
  
    let inSetupToken =
      bLeaf.add_handler [
          PushConst 1;
          Store 0;
		  PopA;
		  EmitTo 2;
      ]
    in
  
    let inAuthToken =
      bLeaf.add_handler [
	      PushConst 1;
		  PopA;
	      Load 0;
		  Eq 1;
		  BranchOf [|
		    [ EmitTo 0];
		    [ EmitTo 1]
		  |];
      ]
    in
	
	let inResetSetup =
      bLeaf.add_handler [
	      PushConst 0;
		  Store 0;
      ]
    in
	
    let out_auth_ok = bLeaf.add_out_port () in
    let out_auth_fail = bLeaf.add_out_port () in
    let out_setup_ok = bLeaf.add_out_port () in
  
    let nodeLeaf = bLeaf.finalize () in
	
	(nodeLeaf, (inSetupToken, inAuthToken, inResetSetup), (out_auth_ok, out_auth_fail, out_setup_ok))
  in
  
  let (nodeLeaf0, (inSetupToken0, inAuthToken0, inResetSetup0), (out_auth_ok0, out_auth_fail0, out_setup_ok0)) = makeLeaf () in
  let (nodeLeaf1, (inSetupToken1, inAuthToken1, inResetSetup1), (out_auth_ok1, out_auth_fail1, out_setup_ok1)) = makeLeaf () in

   
    
  (* ======= Payload Node============*)
  let bPayload = Builder.Node.create ~state:[0] ~vm in
  let inPayload =
     bPayload.add_handler [
      PushA;
	  Store 0;
     ]
  in
  
  let inUnlock =
     bPayload.add_handler [
	  Load 0;
      PopA;
	  EmitTo 0;
     ]
  in
  
  let inClear =
     bPayload.add_handler [
	  PushConst 0;
	  Store 0;
     ]
  in
  
  let out_payload = bPayload.add_out_port () in
  let nodePayload = bPayload.finalize () in
  
  (* ======= Observer Node============*)
  let bObs = Builder.Node.create ~state:[] ~vm in
  
  let inSetupOk =
     bObs.add_handler [
	  PushConst 1;
	  PopA;
	  EmitTo 0;
     ]
  in
  
  let inAuthFail =
     bObs.add_handler [
	  PushConst 1;
	  PopA;
	  EmitTo 1;
     ]
  in

  let out_setup_ok = bObs.add_out_port () in
  let out_auth_fail = bObs.add_out_port () in
  
  let nodeObs = bObs.finalize () in
  
  
  (* ======= Ext Node============*)
  
  let bExt = Builder.Node.create ~state:[] ~vm in
  
  let out_setup_digit = bExt.add_out_port () in
  let out_auth_digit = bExt.add_out_port () in
  let out_ext_payload = bExt.add_out_port () in
  let out_reset_setup = bExt.add_out_port () in
  let out_reset_auth = bExt.add_out_port () in
  let out_clear = bExt.add_out_port () in
  
  let nodeExt = bExt.finalize () in
  
  (* ------------------------------------------------------------ *)
  (* Build network                                                *)
  (* ------------------------------------------------------------ *)
  let nb, ( --> ) = Builder.Net.create () in

  let idExt = nb.add_node nodeExt in
  let idPayload = nb.add_node nodePayload in
  
  let idRouter  = nb.add_node nodeRouter in
  
  let idLeaf0  = nb.add_node nodeLeaf0 in
  let idLeaf1  = nb.add_node nodeLeaf1 in
  
  let idObs = nb.add_node nodeObs in
  

  
    (* Wiring using actual port IDs *)
  (idExt, out_ext_payload) --> (idPayload, inPayload);
  (idExt, out_clear) --> (idPayload, inClear);
  (idLeaf0, out_auth_ok0) --> (idPayload, inUnlock);
  (idLeaf1, out_auth_ok1) --> (idPayload, inUnlock);
  
  (idExt, out_reset_setup) --> (idRouter, inResetSetup);
  (idExt, out_reset_auth) --> (idRouter, inResetAuth);
  (idExt, out_setup_digit) --> (idRouter, inSetupDigit);
  (idExt, out_auth_digit) --> (idRouter, inAuthDigit);
  
  (idRouter, out_setup0) --> (idLeaf0, inSetupToken0);
  (idRouter, out_setup1) --> (idLeaf1, inSetupToken1);
  
  (idRouter, out_auth0) --> (idLeaf0, inAuthToken0);
  (idRouter, out_auth1) --> (idLeaf1, inAuthToken1);
  
  (idExt, out_reset_setup) --> (idLeaf0, inResetSetup0);
  (idExt, out_reset_setup) --> (idLeaf1, inResetSetup1);
  
  (idLeaf0, out_auth_fail0) --> (idObs, inAuthFail);
  (idLeaf1, out_auth_fail1) --> (idObs, inAuthFail);
  (idLeaf0, out_setup_ok0) --> (idObs, inSetupOk);
  (idLeaf1, out_setup_ok1) --> (idObs, inSetupOk);
  
  let net = nb.finalize () in
  
  (* ------------------------------------------------------------ *)
  (* Run simulation                                               *)
  (* ------------------------------------------------------------ *)

let init_snap = Runtime.create ~lifespan:1000 net in

  (* ------------------------------------------------------------ *)
  (* Schedule                                                     *)
  (* ------------------------------------------------------------ *)
  (*let schedule = [
    { Runtime.src = idExt; out_port = out_reset_setup; payload = 1 };
	
    { Runtime.src = idExt; out_port = out_ext_payload; payload = 42 };
    { Runtime.src = idExt; out_port = out_setup_digit; payload = 0 };
	
    { Runtime.src = idEx; out_port = out_reset_auth; payload = 1 };
    { Runtime.src = idExt; out_port = out_auth_digit; payload = 0 };
	
	
    { Runtime.src = idExt; out_port = out_reset_auth; payload = 1 };
    { Runtime.src = idExt; out_port = out_auth_digit; payload = 1 };	
	
  ] in *)

let digest1 =
  Runtime.run init_snap ~schedule:[
    { Runtime.src = idExt; out_port = out_ext_payload; payload = 42 };
    { Runtime.src = idExt; out_port = out_setup_digit; payload = 1 };
	
  ] 
in

let out_setup_ok_stream =
  Digest.node_out_stream_on_port ~node_id:idObs ~out_port:out_setup_ok digest1
in

assert_equal [1] out_setup_ok_stream;

let digest2 =
  Runtime.run digest1.final_snapshot ~schedule:[
    { Runtime.src = idExt; out_port = out_auth_digit; payload = 0 };
  ] 
  
in

let out_auth_fail_stream =
  Digest.node_out_stream_on_port ~node_id:idObs ~out_port:out_auth_fail digest2
in

assert_equal [1] out_auth_fail_stream;

let digest3 =
  Runtime.run digest2.final_snapshot ~schedule:[
    { Runtime.src = idExt; out_port = out_reset_auth; payload = 1 };
    { Runtime.src = idExt; out_port = out_auth_digit; payload = 1 };
  ] 
  
in

let out_auth_fail_stream =
  Digest.node_out_stream_on_port ~node_id:idObs ~out_port:out_auth_fail digest3
in

let out_auth_ok_stream =
  Digest.node_out_stream_on_port ~node_id:idLeaf1 ~out_port:out_auth_ok1 digest3
in

let out_payload_stream =
  Digest.node_out_stream_on_port ~node_id:idPayload ~out_port:out_payload digest3
in

assert_equal [] out_auth_fail_stream;
assert_equal [1] out_auth_ok_stream;
assert_equal [42] out_payload_stream;


Printf.printf "Total steps: %d\n" (Digest.total_steps digest2);
Printf.printf "NodeObs out_setup_ok: %s\n" (pp_list out_setup_ok_stream);
Printf.printf "NodeObs out_auth_fail: %s\n" (pp_list out_auth_fail_stream);
Printf.printf "nodeLeaf1 out_auth_ok: %s\n" (pp_list out_auth_ok_stream);
Printf.printf "nodePayload out_payload: %s\n" (pp_list out_payload_stream)




let suite =
  "digital vault tests" >::: [
    "test digital vault address" >:: test_digital_vault;
  ]

let () = run_test_tt_main suite