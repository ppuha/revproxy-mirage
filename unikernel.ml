open Cmdliner

let port =
  let doc =
    Arg.info ~doc:"The TCP port on which to listen for incoming connections."
      [ "port" ]
  in
  Arg.(value & opt int 7450 doc)

module Main
  (CON : Conduit_mirage.S)
  (C : Cohttp_lwt.S.Client) = struct
    module Revproxy = Revproxy.Make (CON) (C) (Upstream.Static_store)

    let start conduit ctx port = Revproxy.run conduit ctx ~port
end
