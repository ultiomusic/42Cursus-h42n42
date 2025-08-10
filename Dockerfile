# ---------- builder ----------
    FROM ocaml/opam:ubuntu-22.04-ocaml-5.2 AS build
    ENV OPAMYES=1
    
    RUN sudo apt-get update && sudo apt-get install -y \
        m4 pkg-config libgmp-dev zlib1g-dev libsqlite3-dev libssl-dev \
     && sudo rm -rf /var/lib/apt/lists/*
    
    WORKDIR /home/opam/app
    COPY --chown=opam:opam h42n42.opam dune-project ./
    
    RUN opam update && opam install -y dune \
        js_of_ocaml js_of_ocaml-ppx js_of_ocaml-tyxml \
        lwt lwt_ppx tyxml eliom ocsigenserver ocsipersist-sqlite \
        js_of_ocaml-ppx_deriving_json ocsigen-ppx-rpc
    
    COPY --chown=opam:opam . .
    RUN eval $(opam env) && make install
    RUN cp -v _build/default/h42n42_main.exe /home/opam/h42n42
    
    # ---------- runtime ----------
    FROM debian:bookworm-slim
    
    RUN apt-get update && apt-get install -y \
        libsqlite3-0 libssl3 ca-certificates ocaml-findlib \
     && rm -rf /var/lib/apt/lists/*
    
    # Findlib config sabitle
    ENV OCAMLFIND_CONF=/etc/ocamlfind.conf
    
    # Build-time yoluyla uyumluluk için findlib.conf symlink’i
    RUN mkdir -p /home/opam/.opam/5.2/lib \
     && if [ -f /etc/ocamlfind.conf ]; then \
          ln -sf /etc/ocamlfind.conf /home/opam/.opam/5.2/lib/findlib.conf ; \
        elif [ -f /etc/findlib.conf ]; then \
          ln -sf /etc/findlib.conf    /home/opam/.opam/5.2/lib/findlib.conf ; \
        else \
          printf 'path="/usr/lib/ocaml"\ndestdir="/usr/lib/ocaml"\nstublibs="stublibs"\nldconf="ld.conf"\n' \
            > /home/opam/.opam/5.2/lib/findlib.conf ; \
        fi
    
    # 🔧 mime.types'ı build katmanından al ve aynı yola koy
    # (Ocsigen orada arıyor)
    RUN mkdir -p /home/opam/.opam/5.2/lib/ocsigenserver/etc
    COPY --from=build /home/opam/.opam/5.2/lib/ocsigenserver/etc/ \
                      /home/opam/.opam/5.2/lib/ocsigenserver/etc/
    
    WORKDIR /app
    COPY --from=build /home/opam/h42n42 /usr/local/bin/h42n42
    COPY --from=build /home/opam/app/local /app/local
    COPY --from=build /home/opam/app/static /app/static
    
    RUN mkdir -p /app/local/var/log/h42n42 \
                 /app/local/var/data/h42n42 \
                 /app/local/var/run \
     && useradd -m -u 10001 appuser \
     && chown -R appuser:appuser /app
    
    USER appuser
    EXPOSE 8080
    CMD ["/usr/local/bin/h42n42"]
    