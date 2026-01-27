open Node
open Instructions

let pp_stack st =
  "[" ^ (String.concat "; " (List.map string_of_int st)) ^ "]"

let pp_outputs outs =
  "[" ^ (String.concat "; " (List.map (fun (_, v) ->  string_of_int v) outs)) ^ "]"

let run_test name node event_name payload =
  Printf.printf "\n=== %s ===\n" name;
  Printf.printf "Initial state: %s\n" (pp_stack node.state);
  Printf.printf "Payload: %d\n" payload;

  let updated_node, outs =
    Node.handle_event node ~event_name ~payload
  in

  Printf.printf "Final state: %s\n" (pp_stack updated_node.state);
  Printf.printf "Outputs: %s\n" (pp_outputs outs);
  Printf.printf "=== end ===\n%!";
  updated_node

(* AddMod program: compute new_acc and emit it *)
let addmod_prog = [
  AddMod;
  Pop;
  Emit;
]

let () =
  (* VM configuration for all tests *)
  let vm = Vm.create ~stack_capacity:10 ~max_steps:10 in

  (* Test 1: 4 + 3 < 10 → new_acc = 7 *)
  
  let node =
      Node.create ~state:[4; 10] ~vm ()
	  |> Node.add_handler "addmod" addmod_prog in


  ignore (run_test "AddMod: no wrap" node "addmod" 3);

  (* Test 2: 8 + 5 >= 10 → new_acc = 3 *)

  let node =
      Node.create ~state:[8; 10] ~vm ()
	  |> Node.add_handler "addmod" addmod_prog in

  ignore (run_test "AddMod: wrap" node "addmod" 5);

  Printf.printf "\nAll node tests finished.\n%!"
