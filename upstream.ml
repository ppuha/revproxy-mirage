type t = {
  prefix : string;
  upstream_uri  : Uri.t;
}

module type STORE = sig
  val get_upstream : string -> t option
end

module Static_store = struct
  let get_upstream path =
    if String.starts_with ~prefix: "/example" path
      then (Some {
        prefix = "/example";
        upstream_uri = Uri.of_string "http://localhost:7451"
      })
    else None
end

let strip_path_prefix uri ~prefix =
  let path = Uri.path uri in
  let path' =
    if String.starts_with ~prefix path then
      String.sub path
        (String.length prefix)
        (String.length path - String.length prefix)
      else path in
  Uri.with_path uri path'
