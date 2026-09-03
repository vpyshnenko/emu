(* snapshot.ml *)

type t = {
  net : Net.t;
  queue : (int * int * Payload.t) Queue.t;
  max_queue_length : int;
}

let default_max_queue_length = 100

let empty =
  {
    net = Net.create ();
    queue = Queue.empty;
	max_queue_length = default_max_queue_length
  }


let make ~net ?(max_queue_length = default_max_queue_length) () =
  {
    net;
    queue = Queue.empty;
	max_queue_length
  }

let with_net net snap  =
  { snap with net }

let with_queue queue snap =
  { snap with queue }

