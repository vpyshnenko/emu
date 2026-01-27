open OUnit2
open Dlist

let test_empty _ =
  assert_equal [] (to_list empty)

let test_singleton _ =
  assert_equal [42] (to_list (singleton 42))

let test_of_list _ =
  assert_equal [1;2;3] (to_list (of_list [1;2;3]))

let test_cons _ =
  let d = empty |> cons 3 |> cons 2 |> cons 1 in
  assert_equal [1;2;3] (to_list d)

let test_snoc _ =
  let d = empty |> snoc 1 |> snoc 2 |> snoc 3 in
  assert_equal [1;2;3] (to_list d)

let test_append _ =
  let d1 = of_list [1;2] in
  let d2 = of_list [3;4] in
  assert_equal [1;2;3;4] (to_list (append d1 d2))

let test_mixed_ops _ =
  let d =
    empty
    |> cons 3
    |> snoc 4
    |> cons 2
    |> snoc 5
    |> cons 1
  in
  assert_equal [1;2;3;4;5] (to_list d)

let test_map _ =
  let d = of_list [1;2;3] in
  let d2 = map (fun x -> x * 10) d in
  assert_equal [10;20;30] (to_list d2)

let test_fold_left _ =
  let d = of_list [1;2;3;4] in
  let sum = fold_left ( + ) 0 d in
  assert_equal 10 sum

let test_fold_right _ =
  let d = of_list ["a"; "b"; "c"] in
  let s = fold_right (fun x acc -> x ^ acc) d "" in
  assert_equal "abc" s

let test_append_identity _ =
  let d = of_list [1;2;3] in
  assert_equal (to_list d) (to_list (append empty d));
  assert_equal (to_list d) (to_list (append d empty))

let test_append_associativity _ =
  let d1 = of_list [1] in
  let d2 = of_list [2] in
  let d3 = of_list [3] in
  let left  = append (append d1 d2) d3 |> to_list in
  let right = append d1 (append d2 d3) |> to_list in
  assert_equal left right

let suite =
  "Dlist tests" >::: [
    "empty"               >:: test_empty;
    "singleton"           >:: test_singleton;
    "of_list"             >:: test_of_list;
    "cons"                >:: test_cons;
    "snoc"                >:: test_snoc;
    "append"              >:: test_append;
    "mixed_ops"           >:: test_mixed_ops;
    "map"                 >:: test_map;
    "fold_left"           >:: test_fold_left;
    "fold_right"          >:: test_fold_right;
    "append_identity"     >:: test_append_identity;
    "append_associativity">:: test_append_associativity;
  ]

let () = run_test_tt_main suite
