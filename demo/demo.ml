(* dune utop src *)
(* #use "demo/demo.ml";; *)
(* let snap = Demo.initial_snapshot;; *)
(* let Some (snap, steps) = Demo.next_step snap;; *)

open Instructions
open Runtime

module Demo = struct
 let pp_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"
 let vm = Vm.create ~stack_capacity:100 ~max_steps:100 ~mem_size:2
 let ceil = 21

 (* AddMod program *)
 (* Emits:
    - symbolic index 1 if overflow
    - symbolic index 0 otherwise
 *)
 let addmod_prog = [
   Load 1; (* put ceil on the bottom *)
   Load 0; (* put 0 as initial value for counter *)
   PushA; (* push incoming value *)
   AddMod;
   PeekA; (* copy overflow val to regA *)
   EmitIfNonZero 1;   (* emit overflow *)
   Pop;    (* remove overflow val  from stack *)
   PeekA; (* copy sum to reg A *)
   EmitTo 0;          (* default symbolic index *)
   Store 0; (* store sum to mem[0] *)
 ]
 
 (* forward_prog: takes symbolic index for ch_out *)
 let forward_prog ch_out =
   [
	 Load 0; (* copy counter val *)
	 LogStack;
     HaltIfEq (0, 0);
     EmitTo 0;        (* default symbolic index *)
     EmitTo ch_out;   (* symbolic index for ch_out *)
     PushConst (-1);
     Add;
	 LogStack;
	 Store 0;
   ]
 

 (* ------------------------------------------------------------ *)
 (* Node A                                                       *)
 (* ------------------------------------------------------------ *)
 let bA = Builder.Node.create ~state:[0; ceil] ~vm
 let inA = bA.add_handler addmod_prog
 let outA = bA.add_out_port ()     (* actual ID *)
 let outA_overflow = bA.add_out_port () (* actual ID *)
 let nodeA = bA.finalize ()

 (* ------------------------------------------------------------ *)
 (* Node B                                                       *)
 (* ------------------------------------------------------------ *)
 let bB = Builder.Node.create ~state:[0; ceil] ~vm
 let inB = bB.add_handler addmod_prog
 let outB = bB.add_out_port ()
 let outB_overflow = bB.add_out_port ()
 let nodeB = bB.finalize ()

 (* ------------------------------------------------------------ *)
 (* Node C                                                       *)
 (* ------------------------------------------------------------ *)
 (* let limit = 10 *)
 let limit = 2
 let bC = Builder.Node.create ~state:[limit] ~vm

 (* Node C has 3 outgoing ports: default, ch1_out, ch2_out *)
 let outC = bC.add_out_port ()
 let outC_ch1 = bC.add_out_port ()
 let outC_ch2 = bC.add_out_port ()
 
 let () = 
  Printf.printf "C ports: %s\n" (pp_list [outC; outC_ch1; outC_ch2])

 (* Handlers use symbolic indices:
    default = 0
    ch1_out = 1
    ch2_out = 2
 *)
 let inC_ch1 = bC.add_handler (forward_prog 1)
 let inC_ch2 = bC.add_handler (forward_prog 2)
 let inC_overflow = bC.add_handler [Halt]

 let nodeC = bC.finalize ()

 (* ------------------------------------------------------------ *)
 (* Build network using Builder.Net + DSL wiring operator        *)
 (* ------------------------------------------------------------ *)
(* Build network using Builder.Net + DSL wiring operator *)
let nb, op = Builder.Net.create ()
let ( --> ) = op

let idA = nb.add_node nodeA
let idB = nb.add_node nodeB
let idC = nb.add_node nodeC

 let () = 
  Printf.printf "A B C node ids: %s\n" (pp_list [idA; idB; idC])

(* Wiring using actual port IDs *)
let () = 
  (idA, outA) --> (idC, inC_ch1);
  (idC, outC_ch1) --> (idB, inB);
  (idB, outB) --> (idC, inC_ch2);
  (idC, outC_ch2) --> (idA, inA);
  
  (* Overflow wiring *)
  (idB, outB_overflow) --> (idC, inC_overflow);
  (idA, outA_overflow) --> (idC, inC_overflow)

let net = nb.finalize ()


 let step0 = Runtime.create ~lifespan:30 net

 let initial_snapshot =
   Runtime.inject_bang
     ~bang:{ dst = idB; in_port_id = inB; payload = 1 }
     step0
 
 (* ------------------------------------------------------------ *)
 (* Run simulation      step by step                             *)
 (* ------------------------------------------------------------ *)
 let next_step snap =
   match Runtime.step snap with
   | None -> None
   | Some (snap', steps) -> Some (snap', steps)
end