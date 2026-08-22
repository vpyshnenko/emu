(* gen_layout-v3.ml *)
let mem_fields = ["parent_node_id"; "distance"; "count"; "max_node_id"]
let output_fields = ["stp"; "count_init"; "count"]
let input_fields = ["stp_init"; "stp"; "count_init"; "count"]

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
  
  close_out oc
