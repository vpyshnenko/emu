
let run nodeA_id nodeB_id value =
  let net = Netbuilder.attach_ext Net.linear_net nodeA_id in
  let init_snap = Emu.Runtime.create net in
  Emu.Runtime.run init_snap ~schedule:[
    { src = Netbuilder.ext_node_id; out_port = 0; payload = [nodeB_id; value] };
    { src = Netbuilder.ext_node_id; out_port = 0; payload = [nodeB_id; value + 1] };
  ]


