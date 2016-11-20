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
	    $(BUILD_DIR)/src/cloml.o\
	    $(BUILD_DIR)/src/cloml.cmi\
	    $(BUILD_DIR)/src/cloml.cmo\
	    $(BUILD_DIR)/src/cloml.cmx

uninstall:
	ocamlfind remove cloml

define test_purity
	$(eval purity := $(shell ./cloml -p $(1) -s $(2) test/data/$(3) /dev/stdout | grep -i purity |sed -e 's/.*Purity=\([0-9.]*\),.*/\1/g'))
	[ "$(purity)" = "$(4)" ]
endef

test: all
	$(call test_purity,false,TCGA-55-7227-01A-11D-2036-08,TCGA-55-7227.with_rejects.vcf,0.49899270073)
	$(call test_purity,true,TCGA-55-7227-01A-11D-2036-08,TCGA-55-7227.with_rejects.vcf,0.461365079365)