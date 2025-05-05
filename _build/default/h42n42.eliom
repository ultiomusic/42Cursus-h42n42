(* h42n42.eliom *)

(* Application name on server and client *)
let%server application_name = "h42n42"
let%client application_name = Eliom_client.get_application_name ()

(* Optional: database configuration *)
let%server () =
  Ocsipersist_settings.set_db_file "local/var/data/h42n42/h42n42_db"

(* Shared application module *)
module%shared App = Eliom_registration.App (struct
  let application_name = application_name
  let global_data_path = None
end)

(* Persist <head> on client to avoid full reload *)
let%client _ = Eliom_client.persist_document_head ()

(* Define the main service *)
let%server main_service =
  Eliom_service.create
    ~path:(Eliom_service.Path [])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

let%client main_service = ~%main_service

(* Register the handler that generates your HTML+JS tags *)
let%shared () =
  App.register ~service:main_service (fun () () ->
    Lwt.return
      Eliom_content.Html.F.(
        html
          (head
             (title (txt "H42N42 Hello"))
             [ (* CSS link *)
               css_link
                 ~uri:
                   (make_uri
                      ~service:(Eliom_service.static_dir ())
                      ["css"; "h42n42.css"])
                 ()
             ; (* JS loader: empty content with src attribute *)
               script
                 ~a:
                   [ a_src
                       (make_uri
                          ~service:(Eliom_service.static_dir ())
                          ["h42n42.js"]) ]
                 (txt "")
             ])
          (body
             [ h1 [ txt "Merhaba H42N42!" ]
             ; p  [ txt "OCaml + Eliom ile tarayıcıda çalışan simülasyon projeniz burada başlıyor." ]
             ])))
