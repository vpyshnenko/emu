(* gen_layout.ml *)
let mem_fields = ["leader_id"; "seq_id"; "distance";]
let output_fields = ["stp"; "root_tx"; "tx"; "data"]
let input_fields = ["stp_init"; "stp"; "root_rx"; "send"; "rx";]

let generate_type_and_val name fields oc =
  Printf.fprintf oc "type %s = {\n" name;
  List.iter (fun f -> Printf.fprintf oc "  %s : int;\n" f) fields;
  Printf.fprintf oc "}\n\n";
  Printf.fprintf oc "let %s = {\n" name;
  List.iteri (fun i f -> Printf.fprintf oc "  %s = %d;\n" f i) fields;
  Printf.fprintf oc "}\n\n"

let () =
  let oc = open_out "layout.ml" in
  Printf.fprintf oc "(* Generated automatically by gen_layout.ml. Do not edit manually! *)\n\n";
  generate_type_and_val "mem" mem_fields oc;
  
  (* === АВТОГЕНЕРАЦИЯ ФУНКЦИИ TO_STATE === *)
  let fields_access = List.map (fun f -> "mem_values." ^ f) mem_fields in
  let list_str = String.concat "; " fields_access in
  Printf.fprintf oc "let to_state (mem_values : mem) : int list =\n" ;
  Printf.fprintf oc "  [ %s ]\n\n" list_str;
  (* ====================================== *)

  generate_type_and_val "output" output_fields oc;
  
  let ports_str = String.concat "; " (List.map (fun f -> "output." ^ f) output_fields) in
  Printf.fprintf oc "let out_ports = [ %s ]\n\n" ports_str;
  
  generate_type_and_val "input" input_fields oc;
  
  (* Generate make_handlers builder to prevent circular dependencies *)
  let params_str = String.concat " " (List.map (fun f -> "~" ^ f) input_fields) in
  Printf.fprintf oc "let make_handlers %s =\n" params_str;
  Printf.fprintf oc "  Emu.Node.IntMap.empty\n";
  List.iter (fun f ->
    Printf.fprintf oc "  |> Emu.Node.IntMap.add input.%s %s\n" f f
  ) input_fields;
  Printf.fprintf oc "\n";

  (* Generate port-to-string mapping functions *)
  Printf.fprintf oc "let string_of_input_port = function\n";
  List.iteri (fun i f -> Printf.fprintf oc "  | %d -> \"%s\"\n" i f) input_fields;
  Printf.fprintf oc "  | idx -> \"port_\" ^ string_of_int idx\n\n";

  Printf.fprintf oc "let string_of_output_port = function\n";
  List.iteri (fun i f -> Printf.fprintf oc "  | %d -> \"%s\"\n" i f) output_fields;
  Printf.fprintf oc "  | idx -> \"port_\" ^ string_of_int idx\n\n";

  (* Generate mem_names string list *)
  let mem_names_str = String.concat "; " (List.map (fun f -> "\"" ^ f ^ "\"") mem_fields) in
  Printf.fprintf oc "let mem_names = [ %s ]\n" mem_names_str;
  
  close_out oc