
let run () =
  let net = Netbuilder.attach_ext Net.linear_net in
  let init_snap = Emu.Runtime.create net in
  Emu.Runtime.run init_snap ~schedule:[
    { src = Netbuilder.ext_node_id; out_port = 0; payload = [2; 41] };
    { src = Netbuilder.ext_node_id; out_port = 5; payload = [2; 42] };
    { src = Netbuilder.ext_node_id; out_port = 4; payload = [8; 43] };
  ]


