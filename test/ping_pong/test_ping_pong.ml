open OUnit2

open Emu
open Ping_pong

let stp_init ~root_id net = 
  (* 1. Initialize linear network and attach controller nodes *)
  let init_snap = Runtime.create net in
  let stp_digest = Runtime.run init_snap ~schedule:[
    { src = Netbuilder.ext_stp_id; out_port = root_id; payload = [1] }
  ] in
  stp_digest.final_snapshot

	
let test_send_linear _ctx =
  let net = Net.make_linear_net 5 in
  (* let net = Net.cycle_net in *)
  let snap = net
    |> Netbuilder.attach_ext
    |> stp_init ~root_id:2
  in
  let rVal = ref 1000 in 
  let n = Emu.Net.size net in 
  
  (* 3. Matrix loop over all NodeA => NodeB combinations *)
  for src_id = 0 to n - 1 do
    for dst_id = 0 to n - 1 do
      incr rVal;
      (* Generate a unique integer value for each test route *)
      let test_val = !rVal in
	  
      let digest = Runtime.run snap ~schedule:[
          { src = Netbuilder.ext_id; out_port = src_id; payload = [dst_id; test_val] }
      ] in
      let received_vals = Digest.node_out_stream_on_port ~node_id:dst_id ~out_port:Layout.output.data digest in
	  if List.mem test_val received_vals then
          Printf.printf "  \x1b[1;32m[PASS]\x1b[0m Node %d => Node %d | Value: %4d | Steps: %2d\n"
            src_id dst_id test_val (Digest.total_steps digest)
        else 
          Printf.printf "  \x1b[1;31m[FAIL]\x1b[0m Node %d => Node %d | Value: %4d | Packet was LOST!\n"
            src_id dst_id test_val;
	  assert_equal [test_val] received_vals
    done
  done

let suite =
  "ping pong tests" >::: [
    "test send linear" >:: test_send_linear;
  ]

let () = run_test_tt_main suite