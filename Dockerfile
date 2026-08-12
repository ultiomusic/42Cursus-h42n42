FROM ocaml/opam:ubuntu-22.04-ocaml-5.2

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
      libgmp-dev libsqlite3-dev libssl-dev pkg-config zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /home/opam/app \
    && chown opam:opam /home/opam/app
USER opam

WORKDIR /home/opam/app
RUN opam install -y eliom.11.1.1 ocsipersist-sqlite.2.0.0

COPY --chown=opam:opam Makefile h42n42.conf.in ./
COPY --chown=opam:opam src ./src
COPY --chown=opam:opam static ./static
RUN opam exec -- make all

EXPOSE 8080
CMD ["ocsigenserver", "-c", "h42n42.conf.in"]
