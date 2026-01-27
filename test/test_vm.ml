open OUnit2
open Instructions

let run ~stack_capacity ~max_steps state code payload =
  let vm = Vm.create ~stack_capacity ~max_steps in
  Vm.exec_program vm state code payload

let test_push_const _ =
  let state = [10] in
  let code = [PushConst 5] in
  let new_state, outputs =
    run ~stack_capacity:10 ~max_steps:10 state code 0
  in
  assert_equal [5; 0; 10] new_state;
  assert_equal [] outputs

let test_add _ =
  let state = [3; 4] in
  let code = [Add] in
  let new_state, outputs =
    run ~stack_capacity:10 ~max_steps:10 state code 5
  in
  assert_equal [8; 4] new_state;
  assert_equal [] outputs

let test_emit _ =
  let state = [42] in
  let code = [Emit] in
  let new_state, outputs =
    run ~stack_capacity:10 ~max_steps:10 state code 2
  in
  assert_equal [2; 42] new_state;
  assert_equal [("default", 2)] outputs

let test_emit_if_nonzero_zero _ =
  let state = [0] in
  let code = [EmitIfNonZero "default"] in
  let new_state, outputs =
    run ~stack_capacity:10 ~max_steps:10 state code 0
  in
  assert_equal [0; 0] new_state;
  assert_equal [] outputs

let test_emit_if_nonzero_nonzero _ =
  let state = [7] in
  let code = [EmitIfNonZero "default"] in
  let new_state, outputs =
    run ~stack_capacity:10 ~max_steps:10 state code 5
  in
  assert_equal [5; 7] new_state;
  assert_equal [("default", 5)] outputs

let test_pop _ =
  let state = [1; 2; 3] in
  let code = [Pop] in
  let new_state, outputs =
    run ~stack_capacity:10 ~max_steps:10 state code 0
  in
  assert_equal [1; 2; 3] new_state;
  assert_equal [] outputs

let test_addmod_no_wrap _ =
  let state = [3; 4] in
  let code = [AddMod] in
  let new_state, outputs =
    run ~stack_capacity:10 ~max_steps:10 state code 0
  in
  assert_equal [0; 3; 4] new_state;
  assert_equal [] outputs

let test_addmod_wrap _ =
  let state = [7; 10] in
  let code = [AddMod] in
  let new_state, outputs =
    run ~stack_capacity:10 ~max_steps:10 state code 4
  in
  assert_equal [1; 1; 10] new_state;
  assert_equal [] outputs

let test_max_steps _ =
  let state = [] in
  let code = List.init 200 (fun _ -> PushConst 1) in
  assert_raises
    (Failure "VM: max_steps limit exceeded")
    (fun () -> ignore (run ~stack_capacity:200 ~max_steps:50 state code 0))

let test_stack_overflow _ =
  let state = [] in
  let code = [PushConst 1; PushConst 2; PushConst 3] in
  assert_raises
    (Failure "Stack overflow")
    (fun () -> ignore (run ~stack_capacity:2 ~max_steps:10 state code 0))
	
let test_emit_order_single_instr _ =
  let state = [0] in
  let code = [Emit; Emit; Emit; PushConst 1; Emit; PushConst 2; Emit; PushConst 3; Emit;] in
  (* payload = 7, so Emit emits 7 three times *)
  let _, outputs =
    run ~stack_capacity:10 ~max_steps:10 state code 7
  in
  (* VM returns reverse chronological order *)
  assert_equal [("default"),3;("default",2);("default",1);("default",7);("default",7);("default",7)] outputs
  
  let test_emit_order_multi_instr _ =
  let state = [1;2;3] in
  let code = [Emit; Pop; Emit; Pop; Emit; Pop; Emit] in
  (* payload = 1, so first 3 emits emit 1; last 2 emit 0 *)
  let _, outputs =
    run ~stack_capacity:10 ~max_steps:10 state code 0
  in
  (* Expected:  Instr1: Emit → [0] payload  *)
    assert_equal [("default",3);("default",2);("default",1);("default",0)] outputs
  
  let test_mixed_emit_order _ =
  let state = [3;4] in
  let code = [
    Emit;      (* emits payload 2 *)
    Add;       (* pushes 3+2=5 *)
    Emit;      (* emits 5 *)
    PushConst 9;
    Emit       (* emits 9 *)
  ] in
  let _, outputs =
    run ~stack_capacity:10 ~max_steps:10 state code 2
  in
  (* Expected reverse chronological: [9;7;2] *)
  assert_equal [("default",9);("default", 5);("default", 2)] outputs




let suite =
  "vm tests" >:::
  [
    "push_const" >:: test_push_const;
    "add" >:: test_add;
    "emit" >:: test_emit;
    "emit_if_nonzero_zero" >:: test_emit_if_nonzero_zero;
    "emit_if_nonzero_nonzero" >:: test_emit_if_nonzero_nonzero;
    "pop" >:: test_pop;
    "addmod_no_wrap" >:: test_addmod_no_wrap;
    "addmod_wrap" >:: test_addmod_wrap;
    "max_steps" >:: test_max_steps;
    "stack_overflow" >:: test_stack_overflow;
	"emit_order_single_instr" >:: test_emit_order_single_instr;
	"emit_order_multi_instr"  >:: test_emit_order_multi_instr;
	"mixed_emit_order"        >:: test_mixed_emit_order;

  ]

let () = run_test_tt_main suite
