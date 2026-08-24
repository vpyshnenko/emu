open Netbuilder

let make_linear_net () =
  let builder = create () in

  let n0 = add_node builder in
  let n1 = add_node builder in
  let n2 = add_node builder in
  let n3 = add_node builder in
  let n4 = add_node builder in
  let n5 = add_node builder in
  let n6 = add_node builder in
  let n7 = add_node builder in
  let n8 = add_node builder in

  connect builder n0 n1;
  connect builder n1 n2;
  connect builder n2 n3;
  connect builder n3 n4;
  connect builder n4 n5;
  connect builder n5 n6;
  connect builder n6 n7;
  connect builder n7 n8;

  finalize builder
  
let linear_net = make_linear_net ()

let make_cycle_net () =
  let builder = create () in

  let n0 = add_node builder in
  let n1 = add_node builder in
  let n2 = add_node builder in
  let n3 = add_node builder in
  let n4 = add_node builder in
  let n5 = add_node builder in
  let n6 = add_node builder in
  let n7 = add_node builder in

  connect builder n0 n1;
  connect builder n1 n2;
  connect builder n2 n3;
  connect builder n0 n3;
  connect builder n4 n5;
  connect builder n5 n6;
  connect builder n6 n7;
  connect builder n4 n7;
  connect builder n0 n4;
  connect builder n1 n5;
  connect builder n2 n6;
  connect builder n3 n7;
  
  finalize builder
  
let cycle_net = make_cycle_net ()
