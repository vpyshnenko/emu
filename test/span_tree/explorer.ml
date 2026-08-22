(* explorer.ml *)
(* Interactive Step-by-Step History Explorer for OCaml VM Network Emulator *)

module Explorer = struct

  let string_of_any_payload (v : 'a) : string =
    let obj = Obj.repr v in
    if Obj.is_block obj then
      let rec list_to_string (o : Obj.t) =
        if Obj.is_int o then []
        else
          try
            let hd = Obj.obj (Obj.field o 0) in
            let tl = Obj.field o 1 in
            string_of_int hd :: list_to_string tl
          with _ -> []
      in
      let lst = list_to_string obj in
      if lst = [] then "[]" else "[" ^ String.concat "; " lst ^ "]"
    else
      string_of_int (Obj.obj obj)

  let string_of_emitted (emitted : 'a list) : string =
    if emitted = [] then "None"
    else
      let items = List.map (fun pair ->
        let (port, p_val) = Obj.magic pair in
        Printf.sprintf "(port %d: %s)" port (string_of_any_payload p_val)
      ) emitted in
      String.concat ", " items

  let print_step_details idx total (step : Emu.Step.t) =
    Printf.printf "\n\x1b[1;36m=== Step [%d / %d] ===\x1b[0m\n" (idx + 1) total;
    Printf.printf "  \x1b[1;32mEvent:\x1b[0m Node %d ───(port %d)───> Node %d\n" 
      (Emu.Step.src step) (Emu.Step.in_port step) (Emu.Step.dest step);
    Printf.printf "  \x1b[1;33mPayload:\x1b[0m %s\n" (string_of_any_payload (Emu.Step.payload step));
    Printf.printf "  \x1b[1;35mEmitted:\x1b[0m %s\n" 
      (string_of_emitted (Emu.Step.emitted step))

  let explore (d : Emu.Digest.t) =
    let history = 
      let open Emu.Digest in
      d.history
    in
    let total = List.length history in
    if total = 0 then
      print_endline "Explorer: History is empty!"
    else begin
      Printf.printf "\x1b[1;32mLoaded history with %d steps.\x1b[0m\n" total;
      print_endline "Commands:";
      print_endline "  [Enter] or 'n'  : Next step";
      print_endline "  'p'             : Previous step";
      print_endline "  's <node_id>'   : Inspect RAM state of a specific node at this step";
      print_endline "  'h'             : Show current command helper";
      print_endline "  'q'             : Quit explorer";
      
      let rec loop idx =
        if idx < 0 then (
          print_endline "\x1b[1;31mAlready at the beginning of execution history.\x1b[0m";
          loop 0
        ) else if idx >= total then (
          print_endline "\x1b[1;31mReached the end of execution history.\x1b[0m";
          loop (total - 1)
        ) else begin
          let step = List.nth history idx in
          print_step_details idx total step;
          
          print_string "\n\x1b[1;34m(debug) >\x1b[0m ";
          flush stdout;
          let input = String.trim (read_line ()) in
          match String.split_on_char ' ' input with
          | [""] | ["n"] -> 
              loop (idx + 1)
          | ["p"] -> 
              loop (idx - 1)
          | ["h"] ->
              print_endline "Commands: [Enter]/n (Next), p (Prev), s <id> (Inspect RAM), q (Quit)";
              loop idx
          | ["q"] -> 
              print_endline "Exiting interactive debugger. Goodbye!"
          | "s" :: node_str :: _ ->
              (try
                 let node_id = int_of_string node_str in
                 let snap = Emu.Step.snapshot step in
                 let state = Emu.Digest.node_state node_id snap in
                 Printf.printf "  \x1b[1;32mNode %d RAM State:\x1b[0m [%s]\n" 
                   node_id (String.concat "; " (List.map string_of_int state))
               with 
               | Failure _ -> print_endline "Error: Node ID must be an integer."
               | _ -> Printf.printf "Error: Node %s not found in the current network snapshot.\n" node_str);
              loop idx
          | _ ->
              print_endline "Unknown command. Press Enter to go next, 'p' for previous, 's <id>' to inspect RAM, or 'q' to quit.";
              loop idx
        end
      in
      loop 0
    end
end
