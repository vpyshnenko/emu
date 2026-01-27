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

This example (from `test_fib_mod.ml`) builds a small AFSM network that generates Fibonacci numbers modulo a ceiling. ![Fibonacci Network Diagram](docs/images/fib_net.png)
*Diagram: causal flow between nodes A, B, and C in the Fibonacci modulo network.*
Nodes A and B compute values; Node C forwards them and emits the sequence.

## 🧩 Example Description

This network is built from three asynchronous finite‑state machines, each running on Emu’s internal stack‑based virtual machine.

### **NodeA and NodeB — stack‑machine modular summators**

NodeA and NodeB are **stack‑driven AFSMs** that compute Fibonacci values modulo a ceiling.  
Each node maintains two internal state values:

- the current Fibonacci number  
- the modulo ceiling  

When either node receives an event:

1. The VM loads operands from the stack  
2. Performs a modular addition (`AddMod`)  
3. Checks whether the result overflowed the ceiling  
4. Emits either:
   - a **normal result** event, or  
   - an **overflow** event  

After computing the new value, each node **forwards the result to its neighbor** through NodeC.  
Together, A and B form a causal loop that generates the Fibonacci sequence modulo `ceil`.

### **NodeC — orchestrator and safety controller**

NodeC is not a summator.  
It acts as an **orchestrator** with two key responsibilities:

1. **Forwarding events**  
   - Receives values from A and sends them to B  
   - Receives values from B and sends them to A  
   - Emits the resulting sequence on its `out` port  

2. **Controlling execution**  
   - Maintains an internal countdown to limit the number of steps  
   - Halts the entire network if either A or B emits an overflow event  

NodeC is effectively the traffic controller and safety valve of the system.

### **Starting the computation**

The entire network is activated by sending a **bang event** to **NodeB**, injecting the initial value `1`.  
From that moment, the causal loop A → C → B → C → A produces the Fibonacci sequence modulo the ceiling.


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
```
### Running this produces:

```ocaml
1 1 2 3 5 8 13
```
A Fibonacci sequence emerges from simple local rules and causal wiring.

# 📦 Installation
sh
opam install emu
# 🧪 Running the example
sh
dune exec test_fib_mod
# 📚 License
MIT (or your license)


