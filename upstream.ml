module type STORE = sig
  val get_upstream : string -> string option
end

module Static_store = struct
  let get_upstream path =
    if path = "/example" then (Some "http://localhost:7451")
    else None
end
