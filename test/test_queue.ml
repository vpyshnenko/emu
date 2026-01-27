open OUnit2

let test_empty _ =
  let q = Queue.empty in
  assert_bool "empty queue" (Queue.is_empty q);
  assert_equal None (Queue.dequeue q)

let test_enqueue_dequeue _ =
  let q = Queue.empty |> Queue.enqueue 1 |> Queue.enqueue 2 |> Queue.enqueue 3 in
  match Queue.dequeue q with
  | None -> assert_failure "expected element"
  | Some (x1, q1) ->
      assert_equal 1 x1;
      match Queue.dequeue q1 with
      | None -> assert_failure "expected second element"
      | Some (x2, q2) ->
          assert_equal 2 x2;
          match Queue.dequeue q2 with
          | None -> assert_failure "expected third element"
          | Some (x3, q3) ->
              assert_equal 3 x3;
              assert_bool "queue empty" (Queue.is_empty q3)

let test_persistence _ =
  let q0 = Queue.empty in
  let q1 = Queue.enqueue 10 q0 in
  (* q1 must remain unchanged *)
  match Queue.dequeue q1 with
  | Some (x, _) -> assert_equal 10 x
  | None -> assert_failure "expected element"

let suite =
  "Emu.Queue tests" >:::
  [
    "empty" >:: test_empty;
    "enqueue/dequeue" >:: test_enqueue_dequeue;
    "persistence" >:: test_persistence;
  ]

let () = run_test_tt_main suite
