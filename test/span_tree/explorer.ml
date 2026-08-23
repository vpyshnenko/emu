(* explorer.ml *)
(* Interactive Step-by-Step History Explorer for OCaml VM Network Emulator *)

open Emu

module Make (Step : sig
  type t = {
    src_node : int;
    dest_node : int;
    in_port : int;
    payload : int list; (* Adapted to Payload.t / int list *)
    emitted : (int * int list) list;
    snapshot : Snapshot.t;
  }
  val src : t -> int
  val dest : t -> int
  val in_port : t -> int
  val payload : t -> int list
  val emitted : t -> (int * int list) list
  val snapshot : t -> Snapshot.t
end) = struct

  let string_of_payload p =
    "[" ^ (String.concat "; " (List.map string_of_int p)) ^ "]"

  let string_of_emitted emitted =
    String.concat ", " (List.map (fun (port, payload) ->
      Printf.sprintf "(%s: %s)" (Layout.string_of_output_port port) (string_of_payload payload)
    ) emitted)

  let print_step_details idx total (step : Step.t) =
    Printf.printf "\n\x1b[1;36m=== Step [%d / %d] ===\x1b[0m\n" (idx + 1) total;
    Printf.printf "  \x1b[1;32mEvent:\x1b[0m Node %d ───(port %s)───> Node %d\n" 
      (Step.src step) (Layout.string_of_input_port (Step.in_port step)) (Step.dest step);
    Printf.printf "  \x1b[1;33mPayload:\x1b[0m %s\n" (string_of_payload (Step.payload step));
    Printf.printf "  \x1b[1;35mEmitted:\x1b[0m %s\n" 
      (if Step.emitted step = [] then "None" else string_of_emitted (Step.emitted step))

  let print_ram_table node_id (state : int list) =
    let headers = Layout.mem_names in
    let header_count = List.length headers in
    let state_count = List.length state in
    
    let rec take n = function
      | [] -> []
      | _ when n <= 0 -> []
      | x :: xs -> x :: take (n - 1) xs
    in
    
    (* If state has more cells than headers, generate fallback names like "cell_4", "cell_5" *)
    let full_headers = 
      if state_count <= header_count then
        take state_count headers
      else
        let rec make_fallback_names acc i =
          if i >= state_count then List.rev acc
          else make_fallback_names (("cell_" ^ string_of_int i) :: acc) (i + 1)
        in
        headers @ (make_fallback_names [] header_count)
    in
    let rows = List.map string_of_int state in
    
    (* Combine header and value to compute widths *)
    let widths = List.map2 (fun h v -> max (String.length h) (String.length v)) full_headers rows in
    
    (* Helper to pad strings *)
    let pad_center s w =
      let len = String.length s in
      if len >= w then s
      else
        let total_pad = w - len in
        let left_pad = total_pad / 2 in
        let right_pad = total_pad - left_pad in
        (String.make left_pad ' ') ^ s ^ (String.make right_pad ' ')
    in
    
    (* Draw horizontal line *)
    let make_line left mid right sep =
      let repeat s n = String.concat "" (List.init n (fun _ -> s)) in
      left ^ (String.concat mid (List.map (fun w -> repeat sep w) widths)) ^ right
    in
    
    let top_line = make_line "  ┌─" "─┬─" "─┐" "─" in
    let mid_line = make_line "  ├─" "─┼─" "─┤" "─" in
    let bot_line = make_line "  └─" "─┴─" "─┘" "─" in
    
    let header_row = "  │ " ^ (String.concat " │ " (List.map2 pad_center full_headers widths)) ^ " │" in
    let value_row  = "  │ " ^ (String.concat " │ " (List.map2 pad_center rows widths)) ^ " │" in
    
    Printf.printf "  \x1b[1;32mNode %d RAM State:\x1b[0m\n" node_id;
    print_endline top_line;
    print_endline header_row;
    print_endline mid_line;
    print_endline value_row;
    print_endline bot_line

  let explore ?node (d : Digest.t) =
    let full_history = Obj.magic d.history in
    let history = match node with
      | None -> full_history
      | Some node_id ->
          List.filter (fun step -> Step.dest step = node_id) full_history
    in
    let total = List.length history in
    if total = 0 then
      match node with
      | None -> print_endline "Explorer: History is empty!"
      | Some node_id -> Printf.printf "Explorer: No steps found where Node %d is the destination!\n" node_id
    else begin
      (match node with
       | None -> Printf.printf "\x1b[1;32mLoaded full history with %d steps.\x1b[0m\n" total
       | Some node_id -> Printf.printf "\x1b[1;32mFiltered history for Destination Node %d: %d of %d total steps.\x1b[0m\n" 
                           node_id total (List.length full_history));
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
          
          (* Auto-print RAM state of the destination node *)
          (try
             let dest_id = Step.dest step in
             let snap = Step.snapshot step in
             let state = Digest.node_state dest_id snap in
             print_ram_table dest_id state
           with _ -> ());
          
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
                 let snap = Step.snapshot step in
                 let state = Digest.node_state node_id snap in
                 print_ram_table node_id state
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
