(* snapshot.ml *)

type t = {
  net : Net.t;
  queue : (int * int * int) Queue.t;
  lifetime : int;
}

let empty =
  {
    net = Net.create ();
    queue = Queue.empty;
    lifetime = 0;
  }


let make ?(lifetime = 100) ~net () =
  {
    net;
    queue = Queue.empty;
    lifetime;
  }

let with_net snap net =
  { snap with net }

let with_queue queue snap =
  { snap with queue }

let with_lifetime lifetime snap =
  { snap with lifetime }
