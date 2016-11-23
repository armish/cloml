BUILD_DIR=_build
PACKAGES=core cmdliner oml sosa

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
	$(eval purity := \
		$(shell ./cloml --input-vcf test/data/$(1) $(2) \
			| grep -i purity \
			| sed -e 's/.*Purity=\[\(.*\)\],Nu.*/\1/g'
		 )
	)
	[ "$(purity)" = "$(3)" ]
endef

# Test variables/expectations
TEST_VCF_MIXED=TCGA-55-7227.with_rejects.vcf
TEST_VCF_ALL=TCGA-55-7227.vcf
TEST_VCF_NOVAF=TCGA-55-7227.no_vaf.vcf
TEST_PURITY_ALL=0.000,0.500
TEST_PURITY_PASSED=0.000,0.480
TEST_PURITY_NOVAF=.,.
	
test:
	$(call test_purity,$(TEST_VCF_MIXED),"--use-all-variants",$(TEST_PURITY_ALL))
	$(call test_purity,$(TEST_VCF_MIXED),,$(TEST_PURITY_PASSED))
	$(call test_purity,$(TEST_VCF_ALL),,$(TEST_PURITY_ALL))
	$(call test_purity,$(TEST_VCF_ALL),"--use-all-variants",$(TEST_PURITY_ALL))
	$(call test_purity,$(TEST_VCF_NOVAF),"--fail-safe",$(TEST_PURITY_NOVAF))
