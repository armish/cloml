BUILD_DIR=_build
PACKAGES=core cmdliner oml sosa
TEST_PACKAGES=$(PACKAGES) alcotest

.PHONY: all clean test deps testDeps install

all:
	ocamlbuild -use-ocamlfind -tag thread -I src/ \
	    -build-dir $(BUILD_DIR)\
	    $(foreach package, $(PACKAGES),-package $(package))\
	    vcf.cma vcf.cmxs vcf.cmxa \
	    estimate.cma estimate.cmxs estimate.cmxa \
	    cloml.native
	cp $(BUILD_DIR)/src/cloml.native ./cloml

deps:
	opam install $(PACKAGES)

testDeps:
	opam install $(TEST_PACKAGES)

clean:
	ocamlbuild -build-dir $(BUILD_DIR) -clean
	-rm ./cloml 2>/dev/null
	-rm -rf _tests/ 2>/dev/null

install:
	ocamlfind install cloml META\
	    _build/src/cloml.o\
	    _build/src/cloml.cmi\
	    _build/src/cloml.cmo\
	    _build/src/cloml.cmx

uninstall:
	ocamlfind remove cloml

test:
	ocamlbuild -use-ocamlfind -tag thread -I test/ -I src/ \
	  -build-dir $(BUILD_DIR)\
	  $(foreach package, $(TEST_PACKAGES),-package $(package))\
	  test.native
	-mkdir $(BUILD_DIR)/test/data
	cp test/data/* $(BUILD_DIR)/test/data/
	$(BUILD_DIR)/test/test.native
