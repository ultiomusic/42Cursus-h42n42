# H42N42

H42N42 is a browser-based simulation game in which the player keeps a population
of creatures called Creets alive beside a toxic river. The client is written in
OCaml, compiled to JavaScript with Js_of_ocaml, and served by Ocsigen/Eliom.

The project demonstrates typed HTML generation with TyXML, browser DOM and mouse
event handling from OCaml, and cooperative concurrent workflows with Lwt. Every
Creet owns an independent Lwt movement loop.

## Prerequisites

- Docker Engine or Docker Desktop
- Docker Compose (`docker-compose` or the `docker compose` plugin)

No local OCaml, Ocsigen, Eliom, or Js_of_ocaml installation is required. Docker
installs and builds the complete toolchain inside the image.

## Setup and run with Docker

Clone the repository and enter the project directory:

```sh
git clone https://github.com/ultiomusic/h42n42.git
cd h42n42
```

Build and start the application:

```sh
docker-compose up --build
```

With the newer Compose plugin, the equivalent command is:

```sh
docker compose up --build
```

Open <http://localhost:8080> in a browser. The first build can take several
minutes because the OCaml dependencies are compiled inside Docker.

To stop and remove the container, press `Ctrl+C` and run:

```sh
docker-compose down
```

## Controls

Click and hold a green or red Creet, move the mouse, and release it at the
desired position. Creets may also be released outside the normal game area.

## Game rules

- The game starts with seven healthy green Creets.
- Creets move in straight lines, occasionally change direction, and reflect from
  the game-area walls.
- A new healthy Creet is born every eight seconds while at least one healthy
  Creet remains.
- A healthy Creet that touches the toxic river becomes a red sick Creet and
  moves 15% more slowly.
- Contact with a contagious Creet gives a healthy Creet a 2% infection chance
  on every simulation check while contact continues.
- A Creet cannot become infected while the player is dragging it.
- A normal sick Creet is cured only when the player drags and releases it in the
  hospital. Entering the hospital by itself does not cure it.
- Every ten seconds, a sick Creet has a 10% chance to become Berserk and a 10%
  chance to become Mean.
- A purple Berserk Creet grows by 10% every ten seconds and dies when it reaches
  four times its original size.
- A yellow Mean Creet is 15% smaller, chases the nearest healthy Creet, and dies
  after sixty seconds.
- Berserk and Mean Creets cannot be dragged or cured.
- Movement speed increases over time, making the game progressively harder.
- The game ends when no healthy Creet remains.

## Project structure

```text
src/game.eliom       Client-side game simulation and mouse interaction
src/h42n42.eliom     Eliom service, TyXML page, and client startup
static/css/          Game styling
static/images/       Image assets directory required by the project structure
h42n42.conf.in       Ocsigen server configuration
Makefile             all, clean, fclean, and re build targets
Dockerfile           OCaml toolchain, application build, and server command
docker-compose.yml   Application service and port 8080 mapping
```

## Additional features

No optional bonus features are implemented. The project intentionally contains
only the required game mechanics and delivery infrastructure.
