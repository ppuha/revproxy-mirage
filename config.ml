open Mirage

let runtime_args = [
  runtime_arg ~pos:__POS__ "Unikernel.port";
  runtime_arg ~pos:__POS__ "Unikernel.upstream"
]

let make =
  let packages = [ package "cohttp-mirage"; package "duration" ] in
  main ~packages ~runtime_args "Unikernel.Main"
    (conduit @-> http_client @-> job)

let () =
  let stack = generic_stackv4v6 default_network in
  let res_dns = resolver_dns stack in
  let conduit = conduit_direct ~tls:true stack in
  let client = cohttp_client res_dns conduit in
  register "revproxy" [ make $ conduit $ client ]
