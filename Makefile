# vim:filetype=make
OCAMLC     = ocamlfind ocamlc
OCAMLOPT   = ocamlfind ocamlopt
OCAMLDEP   = ocamlfind ocamldep
TEX        = tex
QTEST      = qtest
top_srcdir = .
override OCAMLOPTFLAGS += $(INCS) -w Ael -g -annot -I $(top_srcdir)
override OCAMLFLAGS    += $(INCS) -w Ael -g -annot -I $(top_srcdir)
REQUIRES = batteries dynlink

.PHONY: clean install uninstall reinstall doc loc
.SUFFIXES: .ml .mli .cmo .cmi .cmx .cmxs .tex .dvi .pdf .fw

all: hobbot.pdf hobbot.byte loader.cmo pedia.cmo bookmaker.cmo

doc: hobbot.pdf hobbot.html

GEN_SOURCES = event.ml irc.ml api.ml loader.ml pedia.ml cli.ml turing.ml bookmaker_lib.ml bookmaker.ml
ALL_SOURCES = log.ml $(GEN_SOURCES)

.fw.ml:
	fw hobbot

loader.ml: api.fw
	fw hobbot
bookmaker_lib.ml: bookmaker.fw
	fw hobbot

hobbot.html: $(wildcard *.fw)
	fw hobbot +u

hobbot.tex: $(wildcard *.fw)
	fw hobbot +t

# We'd be glad to depend on *.ml but ocamldep is so slow...
# Use "make -B depend" when you know you changed dependancies.
depend:
	$(OCAMLDEP) $(SYNTAX) -package "$(REQUIRES)" *.ml > $@
include depend

hobbot.byte: log.cmo event.cmo irc.cmo api.cmo cli.cmo
	$(OCAMLC)   -o $@ $(SYNTAX) -package "$(REQUIRES)" -linkpkg $(OCAMLFLAGS) $^

hobbot.opt:  log.cmx event.cmx irc.cmx api.cmx cli.cmx
	$(OCAMLOPT) -o $@ $(SYNTAX) -package "$(REQUIRES)" -linkpkg $(OCAMLOPTFLAGS) $^

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
	@$(RM) -f *.cm[ioxa] *.cmx[as] *.[aso] *.byte *.opt *.annot *.lis *.tex *.pdf *.dvi *.log *.html $(GEN_SOURCES) all_tests.ml depend

loc: $(GEN_SOURCES) log.ml
	@cat $^ | wc -l

# Unit tests

# Tests with qtest

# Note: do NOT include in there module which initer connects to IRC!
TEST_SOURCES = log.ml event.ml irc.ml api.ml bookmaker_lib.ml
all_tests.byte: $(TEST_SOURCES:.ml=.cmo) all_tests.ml
	$(OCAMLC)   -o $@ $(SYNTAX) -package "$(REQUIRES) QTest2Lib" -linkpkg $(OCAMLFLAGS) -w -33 $^

all_tests.ml: $(TEST_SOURCES)
	$(QTEST) --preamble 'open Batteries;;' -o $@ extract $^

check: all_tests.byte
	@echo "Running inline tests"
	@timeout 10s ./$< --shuffle || echo "Fail!"


