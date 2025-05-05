(* src/main.eliom *)
open Eliom_content.Html5.D

(* 1) Servis tanımı: kök URL *)
let service_root =
  Eliom_service.create
    ~path:(Eliom_service.Path []) ~meth:(Eliom_service.Get) ()

(* 2) Sunucu tarafı kayıt: bu fonksiyon kök URL isteklerine cevap verecek *)
let () =
  Eliom_registration.Html5.register
    ~service:service_root
    (fun () () ->
      Lwt.return
        [ html
            (head (title (pcdata "H42N42 Hello")) [])
            (body [ h1 [pcdata "Merhaba H42N42!"] ])
        ])
