open Instructions
open Runtime

module Demo = struct
  let vm = Vm.create ~stack_capacity:100 ~max_steps:100
  let ceil = 5

  let addmod_prog = [
    AddMod;
    EmitIfNonZero "overflow";
    Pop;
    Emit;
  ]

  let nodeA =
    Node.create ~state:[0; ceil] ~vm ()
    |> Node.add_default_handler addmod_prog
	|> Node.add_out_stream "overflow"

  let nodeB =
    Node.create ~state:[0; ceil] ~vm ()
    |> Node.add_default_handler addmod_prog
	|> Node.add_out_stream "overflow"

  let nodeC =
    Node.create ~vm ()
    |> Node.add_default_handler [Emit]

  let limit = 3

  let nodeD =
    Node.create ~state:[limit] ~vm ()
    |> Node.add_default_handler [
         LogStack;
         HaltIfEq (1, 0);
         Emit;
         Pop;
         PushConst (-1);
         Add;
         LogStack;
       ]
    |> Node.add_handler "overflow" [Halt]

  let net0 = Net.create ()
  let net1, idA = Net.add_node nodeA net0
  let net2, idB = Net.add_node nodeB net1
  let net3, idC = Net.add_node nodeC net2
  let net4, idD = Net.add_node nodeD net3

  let net =
    net4
    |> fun n -> Net.connect ~src:idA ~dst:idD n ()
    |> fun n -> Net.connect ~src:idD ~dst:idB n ()
    |> fun n -> Net.connect ~src:idB ~dst:idA n ()
	|> fun n -> Net.connect ~src:idB ~out_stream_alias:"overflow" ~dst:idD ~event_name:"overflow"  n ()
    |> fun n -> Net.connect ~src:idA ~out_stream_alias:"overflow" ~dst:idD ~event_name:"overflow"  n ()

  let step0 = Runtime.create ~lifespan:30 net

  let initial_snapshot =
    Runtime.inject_bang
      ~bang:{ dst = idB; event_name = "default"; payload = 1 }
      step0

  let next_step snap =
    match Runtime.step snap with
    | None -> None
    | Some (snap', steps) -> Some (snap', steps)
end
