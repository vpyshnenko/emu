(* snapshot.ml *)

type t = {
  net : Net.t;
  queue : (int * int * int) Queue.t;
}

let empty =
  {
    net = Net.create ();
    queue = Queue.empty;
  }


let make ~net () =
  {
    net;
    queue = Queue.empty;
  }

let with_net snap net =
  { snap with net }

let with_queue queue snap =
  { snap with queue }

