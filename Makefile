NAME := h42n42
SERVER := src/_server/game.cmo src/_server/h42n42.cmo
CLIENT := src/_client/game.cmo src/_client/h42n42.cmo
MODULE := $(NAME).cma
JAVASCRIPT := static/$(NAME).js
CLIENT_PACKAGES := -package js_of_ocaml-ppx -package lwt_ppx

.PHONY: all clean fclean re

all: $(MODULE) $(JAVASCRIPT)

src/_server/%.type_mli: src/%.eliom Makefile
	cd src && eliomc -ppx -infer $*.eliom

src/_server/%.cmo: src/%.eliom src/_server/%.type_mli Makefile
	cd src && eliomc -ppx -c $*.eliom

src/_client/%.cmo: src/%.eliom src/_server/%.type_mli Makefile
	cd src && js_of_eliom -ppx $(CLIENT_PACKAGES) -c $*.eliom

src/_client/h42n42.cmo: src/_client/game.cmo

$(MODULE): $(SERVER) Makefile
	cd src && eliomc -ppx -a -o ../$@ _server/game.cmo _server/h42n42.cmo

$(JAVASCRIPT): $(CLIENT) Makefile
	cd src && js_of_eliom -ppx $(CLIENT_PACKAGES) -jsopt +bigstringaf/runtime.js \
		-o ../$@ _client/game.cmo _client/h42n42.cmo

clean:
	rm -rf src/_server src/_client

fclean: clean
	rm -f $(MODULE) $(JAVASCRIPT)

re: fclean
	$(MAKE) all
