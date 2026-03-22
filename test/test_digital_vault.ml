open OUnit2
open Emu
open Emu.Instructions

let pp_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"

(* ------------------------------------------------------------ *)
(* Digital Vault (B=3, L=3)                                      *)
(* Password = address sequence                                   *)
(* ------------------------------------------------------------ *)

let test_digital_vault _ctx =
  (* Shared VM defaults *)
  let vm = Vm.create ~stack_capacity:30 ~max_steps:100 ~mem_size:2 in


 
  
    let bRouter = Builder.Node.create ~state:[1;1] ~vm () in
    
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
    let bLeaf = Builder.Node.create ~state:[0] ~vm () in
  
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
  let bPayload = Builder.Node.create ~state:[0] ~vm () in
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
  let bObs = Builder.Node.create ~state:[] ~vm () in
  
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
  
  let bExt = Builder.Node.create ~state:[] ~vm () in
  
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

  nb.add_node nodeExt;
  nb.add_node nodePayload;
  nb.add_node nodeRouter;
  nb.add_node nodeLeaf0;
  nb.add_node nodeLeaf1;
  nb.add_node nodeObs;
  

  
    (* Wiring using actual port IDs *)
  (nodeExt.id, out_ext_payload) --> (nodePayload.id, inPayload);
  (nodeExt.id, out_clear) --> (nodePayload.id, inClear);
  (nodeLeaf0.id, out_auth_ok0) --> (nodePayload.id, inUnlock);
  (nodeLeaf1.id, out_auth_ok1) --> (nodePayload.id, inUnlock);
  
  (nodeExt.id, out_reset_setup) --> (nodeRouter.id, inResetSetup);
  (nodeExt.id, out_reset_auth) --> (nodeRouter.id, inResetAuth);
  (nodeExt.id, out_setup_digit) --> (nodeRouter.id, inSetupDigit);
  (nodeExt.id, out_auth_digit) --> (nodeRouter.id, inAuthDigit);
  
  (nodeRouter.id, out_setup0) --> (nodeLeaf0.id, inSetupToken0);
  (nodeRouter.id, out_setup1) --> (nodeLeaf1.id, inSetupToken1);
  
  (nodeRouter.id, out_auth0) --> (nodeLeaf0.id, inAuthToken0);
  (nodeRouter.id, out_auth1) --> (nodeLeaf1.id, inAuthToken1);
  
  (nodeExt.id, out_reset_setup) --> (nodeLeaf0.id, inResetSetup0);
  (nodeExt.id, out_reset_setup) --> (nodeLeaf1.id, inResetSetup1);
  
  (nodeLeaf0.id, out_auth_fail0) --> (nodeObs.id, inAuthFail);
  (nodeLeaf1.id, out_auth_fail1) --> (nodeObs.id, inAuthFail);
  (nodeLeaf0.id, out_setup_ok0) --> (nodeObs.id, inSetupOk);
  (nodeLeaf1.id, out_setup_ok1) --> (nodeObs.id, inSetupOk);
  
  let net = nb.finalize () in
  
  (* ------------------------------------------------------------ *)
  (* Run simulation                                               *)
  (* ------------------------------------------------------------ *)

let init_snap = Runtime.create net in

  (* ------------------------------------------------------------ *)
  (* Schedule                                                     *)
  (* ------------------------------------------------------------ *)
  (*let schedule = [
    { Runtime.src = nodeExt.id; out_port = out_reset_setup; payload = 1 };
	
    { Runtime.src = nodeExt.id; out_port = out_ext_payload; payload = 42 };
    { Runtime.src = nodeExt.id; out_port = out_setup_digit; payload = 0 };
	
    { Runtime.src = idEx; out_port = out_reset_auth; payload = 1 };
    { Runtime.src = nodeExt.id; out_port = out_auth_digit; payload = 0 };
	
	
    { Runtime.src = nodeExt.id; out_port = out_reset_auth; payload = 1 };
    { Runtime.src = nodeExt.id; out_port = out_auth_digit; payload = 1 };	
	
  ] in *)

let digest1 =
  Runtime.run init_snap ~schedule:[
    { Runtime.src = nodeExt.id; out_port = out_ext_payload; payload = 42 };
    { Runtime.src = nodeExt.id; out_port = out_setup_digit; payload = 1 };
	
  ] 
in

let out_setup_ok_stream =
  Digest.node_out_stream_on_port ~node_id:nodeObs.id ~out_port:out_setup_ok digest1
in

assert_equal [1] out_setup_ok_stream;

let digest2 =
  Runtime.run digest1.final_snapshot ~schedule:[
    { Runtime.src = nodeExt.id; out_port = out_auth_digit; payload = 0 };
  ] 
  
in

let out_auth_fail_stream =
  Digest.node_out_stream_on_port ~node_id:nodeObs.id ~out_port:out_auth_fail digest2
in

assert_equal [1] out_auth_fail_stream;

let digest3 =
  Runtime.run digest2.final_snapshot ~schedule:[
    { Runtime.src = nodeExt.id; out_port = out_reset_auth; payload = 1 };
    { Runtime.src = nodeExt.id; out_port = out_auth_digit; payload = 1 };
  ] 
  
in

let out_auth_fail_stream =
  Digest.node_out_stream_on_port ~node_id:nodeObs.id ~out_port:out_auth_fail digest3
in

let out_auth_ok_stream =
  Digest.node_out_stream_on_port ~node_id:nodeLeaf1.id ~out_port:out_auth_ok1 digest3
in

let out_payload_stream =
  Digest.node_out_stream_on_port ~node_id:nodePayload.id ~out_port:out_payload digest3
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