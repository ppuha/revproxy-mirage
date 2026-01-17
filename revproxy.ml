open Cohttp
open Lwt.Infix

module Make
  (CON : Conduit_mirage.S)
  (C : Cohttp_lwt.S.Client) = struct

  let src = Logs.Src.create "Revproxy" ~doc:"Reverse proxy"
  module Log = (val Logs.src_log src : Logs.LOG)

  module H = Cohttp_mirage.Server.Make (CON)

  let callback ctx _conn req body ~upstream =
    let headers = Request.headers req in
    let upstream_uri = Uri.of_string upstream in
    let target =
      Uri.with_uri
        ?scheme:(Some (Uri.scheme upstream_uri))
        ?host:(Some (Uri.host upstream_uri))
        ?port:(Some (Uri.port upstream_uri))
        (Request.uri req)
    in
    Log.info (fun print -> print "Calling %s" (target |> Uri.to_string));
    C.call ~ctx ~headers ~body (Request.meth req) target >>= fun (resp, body) ->
      Log.info (fun print ->
        print "Got response with headers %s" (Response.headers resp |> Header.to_string));
      H.respond ~headers:(Response.headers resp) ~status:(Response.status resp) ~body ()

  let run conduit ctx ~port ~upstream =
    let spec = H.make ~callback:(callback ctx ~upstream) () in
    H.listen conduit (`TCP port) spec
end
