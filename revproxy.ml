open Cohttp
open Lwt.Infix

module Make
  (CON : Conduit_mirage.S)
  (C : Cohttp_lwt.S.Client)
  (Upstream_store : Upstream.STORE) = struct

  let src = Logs.Src.create "Revproxy" ~doc:"Reverse proxy"
  module Log = (val Logs.src_log src : Logs.LOG)

  module H = Cohttp_mirage.Server.Make (CON)

  let callback ctx _conn req body =
    let headers = Request.headers req in
    let path = Request.uri req |> Uri.path in
    Upstream_store.get_upstream path >>= function
      | None -> H.respond_error ~status:(`Bad_gateway) ~body:String.empty ()
      | Some { prefix; upstream_uri } ->
        let prefix = if String.ends_with ~suffix:"/" prefix then prefix else prefix ^ "/" in
        let target =
          Uri.with_uri
            ~scheme:(Uri.scheme upstream_uri)
            ~host:(Uri.host upstream_uri)
            ~port:(Uri.port upstream_uri)
            ~userinfo: (Uri.userinfo upstream_uri)
            (Request.uri req)
          |> Upstream.strip_path_prefix ~prefix
          in
          Log.info (fun print -> print "Calling %s" (target |> Uri.to_string));
          C.call ~ctx ~headers ~body (Request.meth req) target >>= fun (resp, body) ->
            H.respond ~headers:(Response.headers resp) ~status:(Response.status resp) ~body ()

  let run conduit ctx ~port =
    let spec = H.make ~callback:(callback ctx) () in
    H.listen conduit (`TCP port) spec
end
