[%%server.start]

module Application = Eliom_registration.App (struct
  let application_name = "h42n42"
  let global_data_path = None
end)

let service =
  Eliom_service.create
    ~path:(Eliom_service.Path [])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

let () =
  Application.register ~service (fun () () ->
      let open Eliom_content.Html.D in
      Lwt.return
        (html
           (head
              (title (txt "H42N42"))
              [ meta ~a:[a_charset "utf-8"] ();
                meta
                  ~a:[a_name "viewport"; a_content "width=device-width, initial-scale=1"]
                  ();
                css_link
                  ~uri:(make_uri ~service:(Eliom_service.static_dir ()) ["css"; "h42n42.css"])
                  () ])
           (body
              [ main ~a:[a_id "game"]
                  [ div ~a:[a_class ["river"]] [txt "TOXIC RIVER"];
                    div ~a:[a_class ["hospital"]] [txt "HOSPITAL"];
                    div ~a:[a_id "game-over"; a_class ["game-over"]]
                      [h1 [txt "GAME OVER"]] ] ])))

[%%client.start]

let () =
  Lwt.async (fun () ->
      let%lwt _ = Js_of_ocaml_lwt.Lwt_js_events.onload () in
      Game.start ();
      Lwt.return_unit)
