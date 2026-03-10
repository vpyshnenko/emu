(* stack.ml *)

type t = {
  data : int list;
  stack_capacity : int;
}

let create ~stack_capacity =
  { data = []; stack_capacity }

let is_empty st =
  st.data = []

let push v st =
  if List.length st.data >= st.stack_capacity then
    failwith "Stack overflow"
  else
    { st with data = v :: st.data }

let pop st =
  match st.data with
  | [] -> failwith "Stack underflow"
  | x :: xs -> (x, { st with data = xs })

let peek st =
  match st.data with
  | [] -> failwith "Stack underflow"
  | x :: _ -> x

let to_list st =
  st.data
  
let get_nth st n =
  if n < 0 then failwith "Stack.get_nth: negative index";
  let rec aux st i =
    if i = 0 then peek st
    else
      let _, st' = pop st in
      aux st' (i - 1)
  in
  aux st n


