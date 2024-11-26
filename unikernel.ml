open Cmdliner

let port =
  let doc =
    Arg.info ~doc:"The TCP port on which to listen for incoming connections."
      [ "port" ]
  in
  Arg.(value & opt int 7450 doc)

let upstream =
  let doc =
    Arg.info ~doc:"The upstream URL to reverse proxy to."
      [ "upstream" ]
  in
  Arg.(value & opt string "http://localhost:7451" doc)

module Main
  (CON : Conduit_mirage.S)
  (C : Cohttp_lwt.S.Client) = struct
    module Revproxy = Revproxy.Make (CON) (C)

    let start conduit ctx port upstream = Revproxy.run conduit ctx ~port ~upstream
end
