# vim:filetype=make
OCAMLC     = ocamlfind ocamlc
OCAMLOPT   = ocamlfind ocamlopt
TEX        = tex
QTEST      = qtest
top_srcdir = .
override OCAMLOPTFLAGS += $(INCS) -w Ael -g -annot -I $(top_srcdir)
override OCAMLFLAGS    += $(INCS) -w Ael -g -annot -I $(top_srcdir)
REQUIRES = batteries

.PHONY: clean install uninstall reinstall doc loc

all: hobbot.pdf

doc: hobbot.pdf hobbot.html

GEN_SOURCES = event.ml irc.ml api.ml loader.ml

$(GEN_SOURCES): hobbot.fw
	fw $(basename $<)

hobbot.html: $(wildcard *.fw)
	fw $(basename $@) +u

hobbot.tex: $(wildcard *.fw)
	fw $(basename $@) +t

event.ml: event.fw
irc.ml: irc.fw
api.ml: api.fw
loader.ml: api.fw

api.cmo event.cmo irc.cmo: log.cmo
irc.cmo api.cmo: event.cmo
api.cmo: irc.cmo
loader.cmo: api.cmo

.SUFFIXES: .ml .mli .cmo .cmi .cmx .cmxs .opt .byte .tex .dvi .pdf

.cmo.byte: $(ARCHIVE)
	$(OCAMLC)   -o $@ $(SYNTAX) -package "$(REQUIRES)" -ccopt -L$(top_srcdir) $(ARCHIVE) $(EXTRALIBS) -linkpkg $(OCAMLFLAGS) $^

.cmx.opt: $(XARCHIVE)
	$(OCAMLOPT) -o $@ $(SYNTAX) -package "$(REQUIRES)" -ccopt -L$(top_srcdir) $(XARCHIVE) $(EXTRALIBS:.cma=.cmxa) -linkpkg $(OCAMLOPTFLAGS) $^

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
	
