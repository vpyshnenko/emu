open Layout

let run nodeA_id nodeB_id =
  let net = Netbuilder.attach_ext Net.linear_net nodeA_id in
  let init_snap = Emu.Runtime.create net in
  Emu.Runtime.run init_snap ~schedule:[
    { src = Netbuilder.ext_node_id; out_port = output.ping; payload = [nodeB_id; nodeA_id] };
  ]


