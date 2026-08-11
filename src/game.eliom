[%%client.start]

open Js_of_ocaml
open Js_of_ocaml_lwt

(* Creet state, movement and mutations. *)

type state = Healthy | Sick | Berserk | Mean | Dead

type creet = {
  element : Dom_html.divElement Js.t;
  mutable position_x : float;
  mutable position_y : float;
  mutable direction_x : float;
  mutable direction_y : float;
  mutable radius : float;
  mutable state : state;
  mutable is_being_dragged : bool;
  mutable is_outside_board : bool;
  mutable seconds_until_turn : float;
  mutable seconds_until_mutation : float;
  mutable seconds_as_mean : float;
  mutable seconds_until_growth : float;
  mutable last_update_time : float;
}

let base_radius = 18.
let base_speed = 72.
let river_height = 72.
let hospital_height = 92.
let creet_population : creet list ref = ref []
let difficulty_multiplier = ref 1.
let game_finished = ref false

let current_time () = (new%js Js.date_now)##getTime /. 1000.
let board () = Dom_html.getElementById "game"
let board_width () = float_of_int (board ())##.clientWidth
let board_height () = float_of_int (board ())##.clientHeight

let state_class_name = function
  | Healthy -> "healthy"
  | Sick -> "sick"
  | Berserk -> "berserk"
  | Mean -> "mean"
  | Dead -> ""

let draw creet =
  creet.element##.className :=
    Js.string
      ("creet " ^ state_class_name creet.state
     ^ (if creet.is_being_dragged then " dragging" else ""));
  let diameter = 2. *. creet.radius in
  creet.element##.style##.width := Js.string (Printf.sprintf "%.1fpx" diameter);
  creet.element##.style##.height := Js.string (Printf.sprintf "%.1fpx" diameter);
  creet.element##.style##.left :=
    Js.string (Printf.sprintf "%.1fpx" (creet.position_x -. creet.radius));
  creet.element##.style##.top :=
    Js.string (Printf.sprintf "%.1fpx" (creet.position_y -. creet.radius))

let has_healthy_creet () =
  List.exists (fun creet -> creet.state = Healthy) !creet_population

let game_over () =
  if not !game_finished then (
    game_finished := true;
    (Dom_html.getElementById "game-over")##.className :=
      Js.string "game-over visible")

let set_state creet state =
  creet.state <- state;
  draw creet

let infect_creet creet =
  if creet.state = Healthy && not creet.is_being_dragged then (
    creet.seconds_until_mutation <- 10.;
    set_state creet Sick)

let heal_creet creet = if creet.state = Sick then set_state creet Healthy

let remove_creet creet =
  creet.state <- Dead;
  creet_population :=
    List.filter (fun other_creet -> other_creet != creet) !creet_population;
  Js.Opt.iter creet.element##.parentNode (fun parent ->
      ignore (Dom.removeChild parent (creet.element :> Dom.node Js.t)))

let random_direction () =
  let angle = Random.float (2. *. Float.pi) in
  (cos angle, sin angle)

let nearest_healthy_creet source_creet =
  List.fold_left
    (fun nearest candidate_creet ->
      if candidate_creet.state <> Healthy then nearest
      else
        let distance_squared =
          ((candidate_creet.position_x -. source_creet.position_x) ** 2.)
          +. ((candidate_creet.position_y -. source_creet.position_y) ** 2.)
        in
        match nearest with
        | None -> Some (candidate_creet, distance_squared)
        | Some (_, nearest_distance) when distance_squared < nearest_distance ->
            Some (candidate_creet, distance_squared)
        | _ -> nearest)
    None !creet_population

let chase_nearest_healthy creet =
  match nearest_healthy_creet creet with
  | None -> ()
  | Some (target_creet, _) ->
      let horizontal_offset = target_creet.position_x -. creet.position_x in
      let vertical_offset = target_creet.position_y -. creet.position_y in
      let distance =
        max 0.001
          (sqrt
             ((horizontal_offset *. horizontal_offset)
             +. (vertical_offset *. vertical_offset)))
      in
      creet.direction_x <- horizontal_offset /. distance;
      creet.direction_y <- vertical_offset /. distance

(* A sick Creet receives one roll every ten seconds: 10% Berserk,
   10% Mean, and 80% remains sick until the next roll. *)
let update_special_state creet elapsed_seconds =
  match creet.state with
  | Sick ->
      creet.seconds_until_mutation <-
        creet.seconds_until_mutation -. elapsed_seconds;
      if creet.seconds_until_mutation <= 0. then (
        creet.seconds_until_mutation <- creet.seconds_until_mutation +. 10.;
        let mutation_roll = Random.float 1. in
        if mutation_roll < 0.10 then (
          creet.is_being_dragged <- false;
          creet.seconds_until_growth <- 10.;
          set_state creet Berserk)
        else if mutation_roll < 0.20 then (
          creet.is_being_dragged <- false;
          creet.radius <- base_radius *. 0.85;
          creet.seconds_as_mean <- 0.;
          set_state creet Mean))
  | Berserk ->
      creet.seconds_until_growth <- creet.seconds_until_growth -. elapsed_seconds;
      let rec apply_pending_growth () =
        if creet.state = Berserk && creet.seconds_until_growth <= 0. then (
          creet.seconds_until_growth <- creet.seconds_until_growth +. 10.;
          creet.radius <- creet.radius *. 1.10;
          if creet.radius >= base_radius *. 4. then remove_creet creet
          else apply_pending_growth ())
      in
      apply_pending_growth ()
  | Mean ->
      creet.seconds_as_mean <- creet.seconds_as_mean +. elapsed_seconds;
      chase_nearest_healthy creet;
      if creet.seconds_as_mean >= 60. then remove_creet creet
  | Healthy | Dead -> ()

(* Reflect only the wall-normal velocity component to preserve the
   incidence/reflection angle. *)
let reflect_at_boundaries creet =
  let current_board_width = board_width () in
  let current_board_height = board_height () in
  if creet.position_x -. creet.radius < 0. then (
    creet.position_x <- creet.radius;
    creet.direction_x <- abs_float creet.direction_x)
  else if creet.position_x +. creet.radius > current_board_width then (
    creet.position_x <- current_board_width -. creet.radius;
    creet.direction_x <- -.abs_float creet.direction_x);
  if creet.position_y -. creet.radius < 0. then (
    creet.position_y <- creet.radius;
    creet.direction_y <- abs_float creet.direction_y)
  else if creet.position_y +. creet.radius > current_board_height then (
    creet.position_y <- current_board_height -. creet.radius;
    creet.direction_y <- -.abs_float creet.direction_y)

let is_inside_board creet =
  creet.position_x -. creet.radius >= 0.
  && creet.position_x +. creet.radius <= board_width ()
  && creet.position_y -. creet.radius >= 0.
  && creet.position_y +. creet.radius <= board_height ()

(* The closest point on the rectangle gives an exact circle-zone collision,
   including corners where bounding-box overlap alone would be incorrect. *)
let touches_rectangle creet left top right bottom =
  let horizontal_distance =
    creet.position_x -. max left (min creet.position_x right)
  in
  let vertical_distance =
    creet.position_y -. max top (min creet.position_y bottom)
  in
  (horizontal_distance *. horizontal_distance)
  +. (vertical_distance *. vertical_distance)
  <= creet.radius *. creet.radius

let is_touching_river creet =
  touches_rectangle creet 0. 0. (board_width ()) river_height

(* This recursive Lwt loop is the independent movement thread for one Creet. *)
let rec movement_loop creet =
  if !game_finished || creet.state = Dead then Lwt.return_unit
  else (
    let update_time = current_time () in
    let elapsed_seconds = max 0. (update_time -. creet.last_update_time) in
    creet.last_update_time <- update_time;
    update_special_state creet elapsed_seconds;
    if not creet.is_being_dragged && creet.state <> Dead then (
      creet.seconds_until_turn <- creet.seconds_until_turn -. elapsed_seconds;
      if creet.state <> Mean && creet.seconds_until_turn <= 0. then (
        let direction_x, direction_y = random_direction () in
        creet.direction_x <- direction_x;
        creet.direction_y <- direction_y;
        creet.seconds_until_turn <- 3. +. Random.float 5.);
      let movement_speed =
        base_speed
        *. !difficulty_multiplier
        *. (if creet.state = Healthy then 1. else 0.85)
      in
      let distance_travelled = movement_speed *. min 0.1 elapsed_seconds in
      creet.position_x <-
        creet.position_x +. (creet.direction_x *. distance_travelled);
      creet.position_y <-
        creet.position_y +. (creet.direction_y *. distance_travelled);
      if creet.is_outside_board then
        creet.is_outside_board <- not (is_inside_board creet)
      else reflect_at_boundaries creet;
      if creet.state = Healthy && is_touching_river creet then infect_creet creet);
    if creet.state <> Dead then draw creet;
    let%lwt () = Lwt_js.sleep 0.02 in
    movement_loop creet)

let spawn_creet () =
  let direction_x, direction_y = random_direction () in
  let element =
    Eliom_content.Html.D.div
      ~a:[Eliom_content.Html.D.a_class ["creet"; "healthy"]]
      []
    |> Eliom_content.Html.To_dom.of_div
  in
  let minimum_position_y = river_height +. base_radius +. 12. in
  let maximum_position_y =
    max
      (minimum_position_y +. 1.)
      (board_height () -. hospital_height -. base_radius -. 12.)
  in
  let creet =
    {
      element;
      position_x =
        base_radius
        +. Random.float (max 1. (board_width () -. (2. *. base_radius)));
      position_y =
        minimum_position_y
        +. Random.float (max 1. (maximum_position_y -. minimum_position_y));
      direction_x;
      direction_y;
      radius = base_radius;
      state = Healthy;
      is_being_dragged = false;
      is_outside_board = false;
      seconds_until_turn = 3. +. Random.float 5.;
      seconds_until_mutation = 10.;
      seconds_as_mean = 0.;
      seconds_until_growth = 10.;
      last_update_time = current_time ();
    }
  in
  creet_population := creet :: !creet_population;
  Dom.appendChild (board () :> Dom.node Js.t) (element :> Dom.node Js.t);
  draw creet;
  Lwt.async (fun () -> movement_loop creet)

(* Contact, birth and difficulty loops. *)

let creets_are_touching first_creet second_creet =
  let horizontal_distance = first_creet.position_x -. second_creet.position_x in
  let vertical_distance = first_creet.position_y -. second_creet.position_y in
  let combined_radius = first_creet.radius +. second_creet.radius in
  (horizontal_distance *. horizontal_distance)
  +. (vertical_distance *. vertical_distance)
  <= combined_radius *. combined_radius

let is_contagious creet =
  creet.state = Sick || creet.state = Berserk || creet.state = Mean

(* This runs every world tick, so continued contact receives repeated 2% rolls. *)
let check_contact_infection first_creet second_creet =
  if creets_are_touching first_creet second_creet then
    if
      is_contagious first_creet
      && second_creet.state = Healthy
      && Random.float 1. < 0.02
    then infect_creet second_creet
    else if
      is_contagious second_creet
      && first_creet.state = Healthy
      && Random.float 1. < 0.02
    then infect_creet first_creet

let rec check_all_contacts = function
  | [] -> ()
  | first_creet :: remaining_creets ->
      List.iter (check_contact_infection first_creet) remaining_creets;
      check_all_contacts remaining_creets

let rec world_loop () =
  if !game_finished then Lwt.return_unit
  else (
    check_all_contacts !creet_population;
    if not (has_healthy_creet ()) then game_over ();
    let%lwt () = Lwt_js.sleep 0.05 in
    world_loop ())

let rec reproduction_loop () =
  let%lwt () = Lwt_js.sleep 8. in
  if !game_finished then Lwt.return_unit
  else (
    if has_healthy_creet () then spawn_creet ();
    reproduction_loop ())

let rec difficulty_loop () =
  let%lwt () = Lwt_js.sleep 5. in
  if !game_finished then Lwt.return_unit
  else (
    difficulty_multiplier := !difficulty_multiplier +. 0.03;
    difficulty_loop ())

(* Mouse dragging and hospital release. *)

type drag_state = {
  mutable dragged_creet : creet option;
  mutable pointer_offset_x : float;
  mutable pointer_offset_y : float;
  mutable start_position_x : float;
  mutable start_position_y : float;
  mutable has_moved : bool;
}

let current_drag =
  {
    dragged_creet = None;
    pointer_offset_x = 0.;
    pointer_offset_y = 0.;
    start_position_x = 0.;
    start_position_y = 0.;
    has_moved = false;
  }

let mouse_position_on_board (event : Dom_html.mouseEvent Js.t) =
  let board_rectangle = (board ())##getBoundingClientRect in
  ( float_of_int event##.clientX -. board_rectangle##.left,
    float_of_int event##.clientY -. board_rectangle##.top )

let is_draggable creet = creet.state = Healthy || creet.state = Sick

let find_creet_at_position mouse_x mouse_y =
  List.find_opt
    (fun creet ->
      let horizontal_distance = mouse_x -. creet.position_x in
      let vertical_distance = mouse_y -. creet.position_y in
      is_draggable creet
      && (horizontal_distance *. horizontal_distance)
         +. (vertical_distance *. vertical_distance)
         <= creet.radius *. creet.radius)
    !creet_population

let is_touching_hospital creet =
  touches_rectangle
    creet
    0.
    (board_height () -. hospital_height)
    (board_width ())
    (board_height ())

(* Healing requires real pointer movement; a click and release alone does nothing. *)
let release_dragged_creet () =
  match current_drag.dragged_creet with
  | None -> ()
  | Some creet ->
      current_drag.dragged_creet <- None;
      creet.is_being_dragged <- false;
      creet.is_outside_board <- not (is_inside_board creet);
      if
        current_drag.has_moved
        && creet.state = Sick
        && is_touching_hospital creet
      then heal_creet creet
      else if creet.state = Healthy && is_touching_river creet then
        infect_creet creet
      else draw creet

let install_mouse_handlers () =
  Lwt.async (fun () ->
      Lwt_js_events.mousedowns (board () :> Dom_html.eventTarget Js.t)
        (fun event _ ->
          if !game_finished then Lwt.return_unit
          else
            let mouse_x, mouse_y = mouse_position_on_board event in
            match find_creet_at_position mouse_x mouse_y with
            | None -> Lwt.return_unit
            | Some creet ->
                Dom.preventDefault event;
                creet.is_being_dragged <- true;
                current_drag.dragged_creet <- Some creet;
                current_drag.has_moved <- false;
                current_drag.pointer_offset_x <- mouse_x -. creet.position_x;
                current_drag.pointer_offset_y <- mouse_y -. creet.position_y;
                current_drag.start_position_x <- creet.position_x;
                current_drag.start_position_y <- creet.position_y;
                draw creet;
                Lwt.return_unit));
  Lwt.async (fun () ->
      Lwt_js_events.mousemoves Dom_html.document (fun event _ ->
          match current_drag.dragged_creet with
          | None -> Lwt.return_unit
          | Some creet when not (is_draggable creet) ->
              current_drag.dragged_creet <- None;
              Lwt.return_unit
          | Some creet ->
              Dom.preventDefault event;
              let mouse_x, mouse_y = mouse_position_on_board event in
              let next_position_x = mouse_x -. current_drag.pointer_offset_x in
              let next_position_y = mouse_y -. current_drag.pointer_offset_y in
              let horizontal_movement =
                next_position_x -. current_drag.start_position_x
              in
              let vertical_movement =
                next_position_y -. current_drag.start_position_y
              in
              if
                (horizontal_movement *. horizontal_movement)
                +. (vertical_movement *. vertical_movement)
                > 1.
              then current_drag.has_moved <- true;
              creet.position_x <- next_position_x;
              creet.position_y <- next_position_y;
              draw creet;
              Lwt.return_unit));
  Lwt.async (fun () ->
      Lwt_js_events.mouseups Dom_html.document (fun _ _ ->
          release_dragged_creet ();
          Lwt.return_unit))

let start () =
  Random.self_init ();
  for _ = 1 to 7 do
    spawn_creet ()
  done;
  install_mouse_handlers ();
  Lwt.async world_loop;
  Lwt.async reproduction_loop;
  Lwt.async difficulty_loop
