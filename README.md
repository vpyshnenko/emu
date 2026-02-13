# 🐦 Emu  
Emu is a lightweight deterministic execution engine for building and evaluating networks of finite-state machines (FSMs).

It provides a simple, expressive way to:

- define the local behavior of small programmable machines  
- connect them into a statically wired, event-driven network  
- execute the system deterministically through state transitions  
- inspect the complete execution history via immutable snapshots 
---

# 🎯 Why Emu
System design often mixes core logic with concurrency and timing concerns. Emu separates these concerns by isolating state transitions and event flow in a deterministic environment.

Because execution is deterministic and fully reproducible, behavior can be tested, inspected, and debugged step by step. This makes it easier to uncover design flaws — such as incorrect event routing, unintended feedback loops, missing or inconsistent state transitions, or logical contradictions in node behavior — before those structural issues are obscured by timing and concurrency complexity.

# 🚀 Usage


Using Emu typically follows four steps:

## 1. Define node behavior

Each node runs a small deterministic program on a stack-based virtual machine (VM).  
Handlers describe how the node reacts when a value arrives on a specific input port.

A handler can:

- read and update the node’s local state  
- inspect metadata (such as port counts)  
- emit values to output ports  
- halt execution if needed  

Node programs are intentionally small and focused — they should react quickly and perform bounded work.

---

## 2. Define node state

Each node has persistent local state, represented as a list of integers.

The state:

- survives across events  
- is private to the node  
- is updated only by its VM program  

This keeps logic local and explicit.

---

## 3. Connect nodes through topology

Nodes are connected into a **statically wired, event-driven network**.

Connections define subscriptions:

- when a node emits a value on an output port  
- the network routes that value to all subscribed input ports  

There is no dynamic discovery, shared memory, or implicit routing.  
All communication is explicit and defined by the topology.

---

## 4. Execute the system

The engine evaluates the network by processing events one by one.

Internally, Emu:

- maintains a FIFO event queue  
- delivers events to subscribed nodes  
- runs the corresponding VM handler  
- enqueues any emitted values as new events  
- records an immutable snapshot after each transition  

Execution is deterministic:  
given the same initial state and input schedule, the result is always identical.

The full execution history can be inspected afterward for analysis and debugging.

---

# Core Concepts (Recap)

Under the hood, Emu consists of four composable parts:

- **VM** — runs node handler programs  
- **Node** — holds local state and input/output ports  
- **Net** — defines static topology and routing  
- **Executor** — drives event delivery and records snapshots  

Together, they form a small deterministic execution engine for state-machine networks.

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

let make_vm ~mem_size () =
  Vm.create ~stack_capacity:100 ~max_steps:100 ~mem_size
  


let pp_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"
  

(* ------------------------------------------------------------ *)
(* Test: Fibonacci network with AddMod                          *)
(* ------------------------------------------------------------ *)

let test_fibonacci_mod_network _ctx =
  let vm = make_vm ~mem_size:2 () in
  let ceil = 21 in

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
    EmitIfNonZero 1;   (* overflow symbolic index *)
    Pop;    (* remove overflow val  from stack *)
    PeekA; (* copy sum to reg A *)
    EmitTo 0;          (* default symbolic index *)
    Store 0; (* store sum to mem[0] *)
  ] in
  
  (* forward_prog: takes symbolic index for ch_out *)
  let forward_prog ch_out = [
	  Load 0; (* copy counter val *)
      HaltIfEq (0, 0);
      EmitTo 0;        (* default symbolic index *)
      EmitTo ch_out;   (* symbolic index for ch_out *)
      PushConst (-1);
	  Add;
	  Store 0;
    ] in

  (* ------------------------------------------------------------ *)
  (* Node A                                                       *)
  (* ------------------------------------------------------------ *)
  let bA = Builder.Node.create ~state:[0; ceil] ~vm in
  let inA = bA.add_handler addmod_prog in
  let outA = bA.add_out_port () in          (* actual ID *)
  let outA_overflow = bA.add_out_port () in (* actual ID *)
  let nodeA = bA.finalize () in

  (* ------------------------------------------------------------ *)
  (* Node B                                                       *)
  (* ------------------------------------------------------------ *)
  let bB = Builder.Node.create ~state:[0; ceil] ~vm in
  let inB = bB.add_handler addmod_prog in
  let outB = bB.add_out_port () in
  let outB_overflow = bB.add_out_port () in
  let nodeB = bB.finalize () in

  (* ------------------------------------------------------------ *)
  (* Node C                                                       *)
  (* ------------------------------------------------------------ *)
  let limit = 10 in
  let vm = make_vm ~mem_size:1 () in
  
  let bC = Builder.Node.create ~state:[limit] ~vm in

  (* Node C has 3 outgoing ports: default, ch1_out, ch2_out *)
  let outC = bC.add_out_port () in
  let outC_ch1 = bC.add_out_port () in
  let outC_ch2 = bC.add_out_port () in
  

  (* Handlers use symbolic indices:
     default = 0
     ch1_out = 1
     ch2_out = 2
  *)
  let inC_ch1 = bC.add_handler (forward_prog 1) in
  let inC_ch2 = bC.add_handler (forward_prog 2) in
  let inC_overflow = bC.add_handler [Halt] in

  let nodeC = bC.finalize () in

  (* ------------------------------------------------------------ *)
  (* Build network using Builder.Net + DSL wiring operator        *)
  (* ------------------------------------------------------------ *)
  let nb, ( --> ) = Builder.Net.create () in

  let idA = nb.add_node nodeA in
  let idB = nb.add_node nodeB in
  let idC = nb.add_node nodeC in

  (* Wiring using actual port IDs *)
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

(* One avalanche triggered by sending payload=1 to node B *)
let schedule = [
  { Runtime.src = idC; out_port = outC_ch1; payload = 1 };
] in

let digest =
  Runtime.run ~schedule init_snap
in

let res_stream =
  Digest.node_out_stream_on_port ~node_id:idC ~out_port:outC digest
in

Printf.printf "Total steps: %d\n" (Digest.total_steps digest.history);
Printf.printf "NodeC emitted values: %s\n" (pp_list res_stream);

assert_equal [1; 1; 2; 3; 5; 8; 13] res_stream
  

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


