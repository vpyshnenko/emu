let run root_id =
  let net = Netbuilder.attach_ext Net.linear_net root_id in
  let init_snap = Emu.Runtime.create net in
  let digest1 = Emu.Runtime.run init_snap ~schedule:[
    { src = -1; out_port = 0; payload = [1] };
  ] in
  Emu.Runtime.run (Emu.Digest.final_snapshot digest1) ~schedule:[
    { src = -1; out_port = 1; payload = [1] };
  ]


