open Emu.Runtime
open Ext

let pp_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"
  
let get_out_stream node_id port_id digest = 
  Emu.Digest.node_out_stream_on_port ~node_id:node_id ~out_port: port_id digest
  
let get_in_stream node_id port_id digest = 
  Emu.Digest.node_in_stream_on_port_src ~node_id:node_id ~in_port: port_id digest
  

(* Helper function for tap - since OUnit doesn't have tap *)
let tap f x = f x; x

(* Setup a password and value, starting from a digest *)
let setup_password 
    ~ext
    ~password      (* int list: the password digits *)
    ~value         (* int: the secret to store *)
    (digest : Emu.Digest.t) 
  : Emu.Digest.t =
  
  (* Create messages for each password digit *)
  let digit_messages = List.map (fun digit ->
    { src = ext.id; out_port = ext.output.setup_data; payload = digit }
  ) password in
  
  (* Create final message with the value *)
  let value_message = 
    { src = ext.id; out_port = ext.output.setup_data; payload = value } in
  
  (* Run all messages in sequence *)
  Emu.Runtime.run digest.final_snapshot ~schedule:(digit_messages @ [value_message])

(* Authenticate with a password, starting from a digest *)
let auth_password
    ~ext
    ~password      (* int list: the password digits *)
    (digest : Emu.Digest.t)
  : Emu.Digest.t =
  
  (* Create messages for each password digit *)
  let auth_messages = List.map (fun digit ->
    { src = ext.id; out_port = ext.output.auth_data; payload = digit }
  ) password in
  
  (* Run all auth messages *)
  Emu.Runtime.run digest.final_snapshot ~schedule:auth_messages


(* Generate lazy sequence of all passwords of length l with digits 0..n-1 *)
let password_seq ~n ~l : int list Seq.t =
  let rec loop len prefix =
    if len = 0 then
      Seq.return (List.rev prefix)
    else
      Seq.init n Fun.id
      |> Seq.flat_map (fun d -> loop (len - 1) (d :: prefix))
  in
  loop l []

