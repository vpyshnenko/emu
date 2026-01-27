open OUnit2
open Stack

let test_create _ =
  let st = create ~stack_capacity:5 in
  assert_equal [] (to_list st);
  assert_equal true (is_empty st)

let test_push _ =
  let st = create ~stack_capacity:3 in
  let st = push 1 st in
  let st = push 2 st in
  assert_equal [2; 1] (to_list st)

let test_push_overflow _ =
  let st = create ~stack_capacity:2 in
  let st = push 10 st in
  let st = push 20 st in
  assert_raises
    (Failure "Stack overflow")
    (fun () -> ignore (push 30 st))

let test_pop _ =
  let st = create ~stack_capacity:5 in
  let st = push 1 st in
  let st = push 2 st in
  let x, st = pop st in
  assert_equal 2 x;
  assert_equal [1] (to_list st)

let test_pop_underflow _ =
  let st = create ~stack_capacity:5 in
  assert_raises
    (Failure "Stack underflow")
    (fun () -> ignore (pop st))

let test_peek _ =
  let st = create ~stack_capacity:5 in
  let st = push 42 st in
  assert_equal 42 (peek st)

let test_peek_underflow _ =
  let st = create ~stack_capacity:5 in
  assert_raises
    (Failure "Stack underflow")
    (fun () -> ignore (peek st))

let suite =
  "stack tests" >:::
  [
    "create" >:: test_create;
    "push" >:: test_push;
    "push_overflow" >:: test_push_overflow;
    "pop" >:: test_pop;
    "pop_underflow" >:: test_pop_underflow;
    "peek" >:: test_peek;
    "peek_underflow" >:: test_peek_underflow;
  ]

let () = run_test_tt_main suite
