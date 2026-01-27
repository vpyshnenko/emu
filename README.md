# 🐦 Emu  
### *A playground for building networks of communicating finite‑state machines*

Emu is a lightweight runtime for constructing, wiring, and executing **networks of communicating finite‑state machines (FSMs)**.  
It provides a simple, expressive way to:

- define **local behavior** of small programmable machines  
- connect them into a **causal message‑passing network**  
- run the system with **deterministic event‑driven execution**

Emu is not a simulator.  
Each node runs on a **real stack‑based virtual machine**, and the message‑passing layer is **pluggable**.  
The default transport is a shared FIFO queue — ideal for exploration, teaching, and prototyping.

---

# 🎯 Who Emu Is For

Emu is designed for developers, researchers, and system architects who want to validate **high‑level intent** rather than low‑level timing behavior.

### ✔ Validate protocol logic and design intent  
Emu helps uncover:
- incorrect event routing  
- unintended feedback loops  
- missing or inconsistent state transitions  
- logical contradictions in node behavior  

### ✔ Analyze high‑level system structure  
Emu makes it easy to see:
- how data flows through the network  
- which nodes activate and in what order  
- what global behavior emerges from local rules  

### ✔ Prototype architectural ideas before implementation  
Emu lets you quickly:
- sketch a topology  
- define node behavior  
- observe what the system *actually* does  

### ✔ Focus on semantics, not physics  
Emu **does not** model:
- physical time  
- parallel execution  
- races, hazards, metastability  
- delays, jitter, or hardware effects  

This is intentional:  
Emu reveals **semantic** issues, not **electrical** ones.

### ✔ Explore emergent behavior  
Global dynamics arise from:
- local rules  
- topology  
- causal dependencies  

Emu is ideal for studying such systems.

---

# 🚧 Model and Scope

Emu implements a clean, high‑level computational model:

- ✔ deterministic  
- ✔ event‑driven  
- ✔ finite‑state  
- ✔ explicit topology  
- ✔ causal dataflow  

Emu does **not** attempt to model:

- ✘ physical timing  
- ✘ concurrency or interleavings  
- ✘ races, hazards, metastability  
- ✘ nondeterministic transitions  

This keeps Emu predictable, analyzable, and easy to reason about.

---

# 🏗️ Emu as a Real Runtime

Each node in Emu contains a **deterministic stack‑based virtual machine**:

- a stack  
- a small instruction set  
- persistent local state  
- strict, deterministic semantics  

The VM is not simulated — it is an actual execution engine.

The only replaceable component is the **transport layer**.  
You can swap the default FIFO queue for:

- a message bus  
- a hardware interrupt system  
- a distributed transport  
- a custom scheduler  

The node logic and VM remain unchanged.

---

# 🌀 Example: Fibonacci Modulo Network

This example (from `test_fib_mod.ml`) builds a small FSM network that generates Fibonacci numbers modulo a ceiling.

![Fibonacci Network Diagram](docs/images/fib_net.png)  
*Diagram: causal flow between nodes A, B, and C in the Fibonacci modulo network.*

Nodes A and B compute values; Node C forwards them and emits the sequence.

---

## 🧩 Example Description

The network consists of three communicating finite‑state machines, each running on Emu’s internal stack‑based VM.

### **NodeA and NodeB — stack‑machine modular summators**

NodeA and NodeB are small programmable FSMs that compute Fibonacci values modulo a ceiling.  
Each node maintains two pieces of local state:

- the current Fibonacci number  
- the modulo ceiling  

When a node receives an event:

1. The VM loads operands from the stack  
2. Performs modular addition (`AddMod`)  
3. Checks for overflow  
4. Emits either:
   - a **normal result**, or  
   - an **overflow** event  

After computing the new value, each node **sends the result to its neighbor** through NodeC.  
Together, A and B form a causal loop that generates the Fibonacci sequence modulo `ceil`.

---

### **NodeC — orchestrator and safety controller**

NodeC does not perform arithmetic.  
It serves two roles:

1. **Forwarding events**  
   - receives values from A → sends to B  
   - receives values from B → sends to A  
   - emits the resulting sequence on its `out` port  

2. **Controlling execution**  
   - maintains an internal countdown  
   - halts the network if A or B emits an overflow event  

NodeC is the traffic controller and safety valve of the system.

---

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

# 🧪 Running the example
dune test
# 📚 License
MIT (or your license)


