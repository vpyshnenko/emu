# 🐦 Emu  
### *A network automata playground for asynchronous finite‑state machines*

Emu is a lightweight runtime for building, wiring, and running **networks of asynchronous finite‑state machines (AFSMs)**.  
It provides a simple, expressive way to:

- define **local behavior** of tiny machines  
- connect them into a **causal network**  
- run the system with **deterministic event‑driven execution**

Emu is not a simulator.  
Each node runs on a **real virtual machine**, and the message‑passing layer is **pluggable**.  
The default transport is a shared FIFO queue — ideal for exploration and teaching.

---

## 🚧 Scope: AFSMs Only

Emu intentionally supports **only asynchronous finite‑state machines**:

- ✔ event‑driven  
- ✔ deterministic  
- ✔ finite state  
- ✔ explicit topology  
- ✔ causal execution  

Emu does **not** support:

- ✘ synchronous automata  
- ✘ timed automata  
- ✘ nondeterministic transitions  
- ✘ concurrency or interleavings  

This narrow focus keeps Emu simple, predictable, and easy to reason about.

---

# 🏗️ Emu as a Real Runtime

Each node in Emu contains a **real, deterministic virtual machine**:

- stack  
- instruction set  
- persistent state  
- deterministic semantics  

The VM is not simulated — it is an actual execution engine that can run anywhere.

The only replaceable part is the **transport layer**.  
The default is a shared FIFO queue, but you can swap it for:

- a message bus  
- a hardware interrupt system  
- a distributed transport  
- a custom scheduler  

The node logic and VM stay the same.

---

# 🎓 Educational Onboarding Path

A recommended learning path for newcomers:

### **1 — Run your first network**  
Use the Fibonacci example below.

### **2 — Learn what a Node is**  
A node has:
- local state  
- handlers (VM programs)  
- output ports  

### **3 — Learn how topology works**  
Connections define how events flow.

### **4 — Learn the VM basics**  
Instructions like `Load`, `Add`, `Emit`, `Halt`.

### **5 — Build your own tiny network**  
Start with two nodes sending numbers back and forth.

### **6 — Explore emergent behavior**  
Feedback loops, oscillations, counters, pipelines.

---

# 🌀 Example: Fibonacci Modulo Network

This example (from `test_fib_mod.ml`) builds a small AFSM network that generates Fibonacci numbers modulo a ceiling.  
Nodes A and B compute values; Node C forwards them and emits the sequence.

```ocaml
open OUnit2
open Instructions

let make_vm () =
  Vm.create ~stack_capacity:100 ~max_steps:100

let pp_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"
  

(* ------------------------------------------------------------ *)
(* Test: Fibonacci network with AddMod                          *)
(* ------------------------------------------------------------ *)

let test_fibonacci_mod_network _ctx =
  let vm = make_vm () in
  let ceil = 21 in

  (* AddMod program *)
  let addmod_prog = [
    AddMod;
    EmitIfNonZero "overflow"; 
    Pop;
    EmitTo "default";
  ] in
  
  let forward_prog ch_out =
    [
      LogStack;
      HaltIfEq (1, 0);
      EmitTo "default";
      EmitTo ch_out;
      Pop;
      PushConst (-1);
      Add;
      LogStack;
    ]
  in

  (* ------------------------------------------------------------ *)
  (* Node A                                                       *)
  (* ------------------------------------------------------------ *)
  let bA = Builder.Node.create ~state:[0; ceil] ~vm in
  let inA = bA.add_handler addmod_prog in
  let outA = bA.add_out_port "default" in
  let outA_overflow = bA.add_out_port "overflow" in
  let nodeA = bA.finalize () in

  (* ------------------------------------------------------------ *)
  (* Node B                                                       *)
  (* ------------------------------------------------------------ *)
  let bB = Builder.Node.create ~state:[0; ceil] ~vm in
  let inB = bB.add_handler addmod_prog in
  let outB = bB.add_out_port "default" in
  let outB_overflow = bB.add_out_port "overflow" in
  let nodeB = bB.finalize () in

  (* ------------------------------------------------------------ *)
  (* Node C                                                       *)
  (* ------------------------------------------------------------ *)
  let limit = 10 in
  let bC = Builder.Node.create ~state:[limit] ~vm in

  let inC_ch1 = bC.add_handler (forward_prog "ch1_out") in
  let inC_ch2 = bC.add_handler (forward_prog "ch2_out") in
  let inC_overflow = bC.add_handler [Halt] in

  let outC = bC.add_out_port "default" in
  let outC_ch1 = bC.add_out_port "ch1_out" in
  let outC_ch2 = bC.add_out_port "ch2_out" in

  let nodeC = bC.finalize () in

  (* ------------------------------------------------------------ *)
  (* Build network using Builder.Net + DSL wiring operator        *)
  (* ------------------------------------------------------------ *)
  let nb, ( --> ) = Builder.Net.create () in

  let idA = nb.add_node nodeA in
  let idB = nb.add_node nodeB in
  let idC = nb.add_node nodeC in

  (* Wiring *)
  (idA, outA) --> (idC, inC_ch1);
  (idC, outC_ch1) --> (idB, inB);
  (idB, outB) --> (idC, inC_ch2);
  (idC, outC_ch2) --> (idA, inA);

  (* Overflow wiring *)
  (idB, outB_overflow) --> (idC, inC_overflow);
  (idA, outA_overflow) --> (idC, inC_overflow);

  let net = nb.finalize () in

  (* ------------------------------------------------------------ *)
  (* Run simulation                                               *)
  (* ------------------------------------------------------------ *)
  let init_snap = Runtime.create ~lifespan:30 net in

  let digest =
    Runtime.run
      ~bang:{ dst = idB; in_port_id = inB; payload = 1 }
      init_snap
  in

  let res_stream =
    Digest.node_out_stream_on_port ~node_id:idC ~out_port:outC digest
  in
  
  assert_equal [1; 1; 2; 3; 5; 8; 13] res_stream;

  Printf.printf "Total steps: %d\n" (Digest.total_steps digest.history);
  Printf.printf "NodeC emitted values: %s\n" (pp_list res_stream)


(* ------------------------------------------------------------ *)

let suite =
  "runtime tests" >::: [
    "test fibonacci modulo" >:: test_fibonacci_mod_network;
  ]

let () = run_test_tt_main suite
