(* ============================================ *)
(* 1. Base Types                               *)
(* ============================================ *)

Definition NodeId  := nat.
Definition InPort  := nat.
Definition OutIndex := nat.
Definition PortId  := nat.
Definition Value   := Z.   (* mathematical integers *)

(* ============================================ *)
(* 2. Instructions                             *)
(* ============================================ *)

Inductive instr :=
| Pop
| PushConst (n : Z)
| Add
| AddMod
| LogStack
| PushA
| PopA
| PeekA
| Load (i : nat)
| Store (i : nat)
| LoadMeta (i : nat)
| Emit                 (* emit to slot = top of stack *)
| EmitTo (k : nat)
| EmitIfNonZero (k : nat)
| Halt
| HaltIfEq (n : nat) (x : Z).

Definition Program := list instr.

(* ============================================ *)
(* 3. VM Configuration                         *)
(* ============================================ *)

Record vm_cfg := {
  stack_capacity : nat;
  max_steps      : nat;
  mem_size       : nat;
}.

(* ============================================ *)
(* 4. Node and Network                         *)
(* ============================================ *)

Record node := {
  node_id    : NodeId;
  node_state : list Z;
  node_vm    : vm_cfg;
  handlers   : InPort -> option Program;
  out_ports  : list PortId;
  halted     : bool;
}.

Definition routing :=
  (NodeId * PortId) -> list (NodeId * InPort).

Record net := {
  nodes   : NodeId -> option node;
  route   : routing;
}.

(* ============================================ *)
(* 5. Runtime State                            *)
(* ============================================ *)

Definition event := (NodeId * PortId * Value)%type.

Record snapshot := {
  snap_net      : net;
  snap_queue    : list event;   (* FIFO: head is next *)
  snap_lifetime : nat;
}.

(* ============================================ *)
(* 6. VM Abstract Result                       *)
(* ============================================ *)

Record vm_result := {
  vm_new_state : list Z;
  vm_outputs   : list (OutIndex * Value);  (* newest-first *)
  vm_halted    : bool;
}.

Parameter VMExec :
  node -> Program -> Value -> vm_result.

(* VMExec abstracts the detailed stack machine.
   It must satisfy bounds and max_steps behavior. *)

(* ============================================ *)
(* 7. Node Semantics                           *)
(* ============================================ *)

Definition resolve_out
  (n : node)
  (k : OutIndex)
  : option PortId :=
  nth_error (out_ports n) k.

Definition handle_event
  (n : node)
  (in_p : InPort)
  (payload : Value)
  : option (node * list (PortId * Value)) :=
  if halted n then
    Some (n, [])
  else
    match handlers n in_p with
    | None => None
    | Some prog =>
        let r := VMExec n prog payload in
        let outs :=
          map (fun '(k,v) =>
                 match resolve_out n k with
                 | Some pid => Some (pid, v)
                 | None => None
                 end)
              (vm_outputs r)
        in
        if forallb (fun x =>
              match x with Some _ => true | None => false end)
           outs
        then
          let outs_phys :=
            map (fun x =>
              match x with Some p => p | None => (0%nat,0%Z) end)
            outs
          in
          Some ({|
            node_id    := node_id n;
            node_state := vm_new_state r;
            node_vm    := node_vm n;
            handlers   := handlers n;
            out_ports  := out_ports n;
            halted     := vm_halted r;
          |}, outs_phys)
        else None
    end.

(* ============================================ *)
(* 8. Routing Expansion                        *)
(* ============================================ *)

Definition subscribers
  (nt : net)
  (src : NodeId)
  (p   : PortId)
  : list (NodeId * InPort) :=
  route nt (src, p).

(* ============================================ *)
(* 9. Enqueue                                  *)
(* ============================================ *)

Definition enqueue
  (e : event)
  (s : snapshot)
  : option snapshot :=
  match snap_lifetime s with
  | O => None
  | S L' =>
      Some {|
        snap_net      := snap_net s;
        snap_queue    := snap_queue s ++ [e];
        snap_lifetime := L';
      |}
  end.

(* ============================================ *)
(* 10. Small-Step Transition                   *)
(* ============================================ *)

Inductive step : snapshot -> snapshot -> Prop :=

| StepEvent :
    forall s src p v rest
           nt subs s',
      snap_queue s = (src,p,v) :: rest ->
      subs = subscribers (snap_net s) src p ->

      (* fold-left over subscribers *)
      fold_left
        (fun acc '(dst,in_p) =>
           match acc with
           | None => None
           | Some st =>
               match nodes (snap_net st) dst with
               | None => None
               | Some nd =>
                   match handle_event nd in_p v with
                   | None => None
                   | Some (nd', outs) =>
                       let nt' :=
                         {| nodes := fun id =>
                              if Nat.eqb id dst then Some nd'
                              else nodes (snap_net st) id;
                            route := route (snap_net st) |}
                       in
                       let st1 :=
                         {| snap_net := nt';
                            snap_queue := rest;
                            snap_lifetime := snap_lifetime st |}
                       in
                       (* reverse outs before enqueue *)
                       fold_left
                         (fun acc2 '(op,v2) =>
                            match acc2 with
                            | None => None
                            | Some st2 =>
                                enqueue (dst,op,v2) st2
                            end)
                         (rev outs)
                         (Some st1)
                   end
               end
           end)
        subs
        (Some {| snap_net := snap_net s;
                 snap_queue := rest;
                 snap_lifetime := snap_lifetime s |})
      = Some s' ->
      step s s'.

(* ============================================ *)
(* 11. Terminal State                          *)
(* ============================================ *)

Definition terminal (s : snapshot) : Prop :=
  snap_queue s = [].

