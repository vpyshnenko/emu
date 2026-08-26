

let run n =
  let net = Netbuilder.attach_ext (Net.make_linear_net n) in
  let init_snap = Emu.Runtime.create net in
  Emu.Runtime.run init_snap ~schedule:[
    { src = Netbuilder.ext_node_id; out_port = 0; payload = [(n - 1); 42] };
    (* { src = Netbuilder.ext_node_id; out_port = 5; payload = [2; 42] }; *)
    (* { src = Netbuilder.ext_node_id; out_port = 4; payload = [8; 43] }; *)
  ]

(** Returns the 0-based step index of the first simulation step 
    that emitted a packet on the specified [out_port]. *)
let first_emission_step ~out_port (d : Emu.Digest.t) : int option =
  let rec find_idx idx = function
    | [] -> None (* No emission ever occurred *)
    | step :: rest ->
        (* Extract emissions from this step *)
        let emissions = Emu.Step.emitted step in
        (* Check if any emission matches our target output port *)
        let has_emission = List.exists (fun (port, _) -> port = out_port) emissions in
        if has_emission then 
          Some idx 
        else 
          find_idx (idx + 1) rest
  in
  find_idx 0 d.history


