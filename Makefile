# vim:filetype=make
OCAMLC     = ocamlfind ocamlc
OCAMLOPT   = ocamlfind ocamlopt
TEX        = tex
QTEST      = qtest
top_srcdir = .
override OCAMLOPTFLAGS += $(INCS) -w Ael -g -annot -I $(top_srcdir)
override OCAMLFLAGS    += $(INCS) -w Ael -g -annot -I $(top_srcdir)
REQUIRES = batteries dynlink

.PHONY: clean install uninstall reinstall doc loc

all: hobbot.pdf hobbot.byte

doc: hobbot.pdf hobbot.html

GEN_SOURCES = event.ml irc.ml api.ml loader.ml cli.ml

$(GEN_SOURCES): hobbot.fw
	fw $(basename $<)

hobbot.html: $(wildcard *.fw)
	fw $(basename $@) +u

hobbot.tex: $(wildcard *.fw)
	fw $(basename $@) +t

api.cmo event.cmo irc.cmo: log.cmo
irc.cmo api.cmo: event.cmo log.cmo
api.cmo: irc.cmo log.cmo
cli.cmo: api.cmo irc.cmo event.cmo log.cmo
loader.cmo: api.cmo log.cmo

hobbot.byte: log.cmo event.cmo irc.cmo api.cmo cli.cmo
	$(OCAMLC)   -o $@ $(SYNTAX) -package "$(REQUIRES)" -linkpkg $(OCAMLFLAGS) $^

hobbot.opt:  log.cmx event.cmx irc.cmx api.cmx cli.cmx
	$(OCAMLOPT) -o $@ $(SYNTAX) -package "$(REQUIRES)" -linkpkg $(OCAMLOPTFLAGS) $^

.SUFFIXES: .ml .mli .cmo .cmi .cmx .cmxs .tex .dvi .pdf

.ml.cmo:
	$(OCAMLC) $(SYNTAX) -package "$(REQUIRES)" $(OCAMLFLAGS) -c $<

.mli.cmi:
	$(OCAMLC) $(SYNTAX) -package "$(REQUIRES)" $(OCAMLFLAGS) -c $<

.ml.cmx:
	$(OCAMLOPT) $(SYNTAX) -package "$(REQUIRES)" $(OCAMLOPTFLAGS) -c $<

.ml.cmxs:
	$(OCAMLOPT) $(SYNTAX) -package "$(REQUIRES)" $(OCAMLOPTFLAGS) -o $@ -shared $<

.tex.dvi:
	$(TEX) $<

.dvi.pdf:
	dvipdf $< $@

clean:
	@rm -f *.cm[ioxa] *.cmxa *.cmxs *.a *.s *.o *.byte *.opt *.annot *.lis *.tex *.pdf *.dvi *.log *.html $(GEN_SOURCES)

loc: $(GEN_SOURCES)
	@cat $^ | wc -l

