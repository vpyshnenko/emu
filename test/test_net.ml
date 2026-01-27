(* test_net.ml *)

open OUnit2

module IntMap = Map.Make(Int)

(* ---- Helper to create a dummy node using the real VM ---- *)

let dummy_node () =
  let vm = Vm.create ~stack_capacity:10 ~max_steps:10 in
  Node.create ~vm ()

(* ---- Tests ---- *)

let test_create _ =
  let net = Net.create () in
  assert_equal 0 (IntMap.cardinal net.nodes);
  assert_equal 0 (IntMap.cardinal net.routing)

let test_add_node _ =
  let net =
    Net.create ()
    |> Net.add_node 1 (dummy_node ())
    |> Net.add_node 2 (dummy_node ())
  in
  assert_bool "node 1 exists" (Option.is_some (Net.find_node 1 net));
  assert_bool "node 2 exists" (Option.is_some (Net.find_node 2 net));
  assert_bool "node 3 missing" (Option.is_none (Net.find_node 3 net))

let test_connect _ =
  let net =
    Net.create ()
    |> Net.add_node 1 (dummy_node ())
    |> Net.add_node 2 (dummy_node ())
    |> Net.connect ~src:1 ~dst:2 ~event_name:"ping"
  in
  match Net.subscribers net 1 with
  | None -> assert_failure "expected subscribers for node 1"
  | Some lst ->
      assert_equal 1 (List.length lst);
      assert_equal (2, "ping") (List.hd lst)

let test_multiple_connects _ =
  let net =
    Net.create ()
    |> Net.add_node 1 (dummy_node ())
    |> Net.add_node 2 (dummy_node ())
    |> Net.add_node 3 (dummy_node ())
    |> Net.connect ~src:1 ~dst:2 ~event_name:"ping"
    |> Net.connect ~src:1 ~dst:3 ~event_name:"pong"
  in
  match Net.subscribers net 1 with
  | None -> assert_failure "expected subscribers for node 1"
  | Some lst ->
      (* connect prepends, so order is reversed *)
      assert_equal [(3, "pong"); (2, "ping")] lst

let suite =
  "Net tests" >::: [
    "create" >:: test_create;
    "add_node" >:: test_add_node;
    "connect" >:: test_connect;
    "multiple_connects" >:: test_multiple_connects;
  ]

let () = run_test_tt_main suite
