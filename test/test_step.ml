open OUnit2


(* A tiny fake snapshot for testing *)
let fake_snapshot =  Snapshot.empty



let test_make_step _ =
  let step =
    Step.make
      ~src_node:1
      ~dest_node:2
      ~event_name:"tick"
      ~payload:7
      ~emitted:[10; 20]
      ~snapshot:fake_snapshot
  in

  assert_equal 1 (Step.src step);
  assert_equal 2 (Step.dest step);
  assert_equal "tick" (Step.event step);
  assert_equal 7 (Step.payload step);
  assert_equal [10; 20] (Step.emitted step);
  assert_bool "snapshot preserved" (Step.snapshot step == fake_snapshot)

let test_predicates _ =
  let step =
    Step.make
      ~src_node:3
      ~dest_node:5
      ~event_name:"ping"
      ~payload:99
      ~emitted:[1]
      ~snapshot:fake_snapshot
  in

  assert_bool "is_from_node true" (Step.is_from_node ~node_id:3 step);
  assert_bool "is_from_node false" (not (Step.is_from_node ~node_id:4 step));

  assert_bool "is_for_node true" (Step.is_for_node ~node_id:5 step);
  assert_bool "is_for_node false" (not (Step.is_for_node ~node_id:6 step));

  assert_bool "is_event true" (Step.is_event ~name:"ping" step);
  assert_bool "is_event false" (not (Step.is_event ~name:"tick" step));

  assert_bool "matches_input true"
    (Step.matches_input ~node_id:5 ~event_name:"ping" step);

  assert_bool "matches_input false (wrong node)"
    (not (Step.matches_input ~node_id:3 ~event_name:"ping" step));

  assert_bool "matches_input false (wrong event)"
    (not (Step.matches_input ~node_id:5 ~event_name:"tick" step))

let suite =
  "Step tests" >:::
    [
      "make_step" >:: test_make_step;
      "predicates" >:: test_predicates;
    ]

let () =
  run_test_tt_main suite
