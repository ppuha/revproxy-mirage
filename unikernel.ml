open Lwt.Infix
open Cohttp
open Cohttp_lwt
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

module Revproxy 
  (CON : Conduit_mirage.S)
  (C : Cohttp_lwt.S.Client) = struct

  let src = Logs.Src.create "Revproxy" ~doc:"Reverse proxy"
  module Log = (val Logs.src_log src : Logs.LOG)
  
  module H = Cohttp_mirage.Server.Make (CON)

  let callback ctx _conn req body ~upstream =
    let headers = Request.headers req in
    Log.debug (fun print -> print "Calling %s" upstream);
    C.call ~ctx ~headers ~body (Request.meth req) (Uri.of_string upstream) >>= fun (resp, body) ->
      H.respond ~status:(Response.status resp) ~body ()

  let start conduit ctx port upstream =
    let spec = H.make ~callback:(callback ctx ~upstream) () in
    H.listen conduit (`TCP port) spec
end