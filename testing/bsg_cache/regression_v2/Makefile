include ../../../../bsg_cadenv/cadenv.mk
export BASEJUMP_STL_DIR = $(abspath ../../..)

INCDIR =  +incdir+$(BASEJUMP_STL_DIR)/bsg_misc

VCS_FLAGS =  -full64 +lint=all,noSVA-UA,noSVA-NSVU,noVCDE -debug_access
VCS_FLAGS += +v2k -sverilog -timescale=1ps/1ps -O4


##### Test Suite #######
BASIC_TEST = test_random1


########################

HIGHLIGHT = grep --color -E '^|Fatal|Error|Warning|Implicit wire is used|Too few instance port connections|Port connection width mismatch|Width mismatch'


### TEST parameters ####
########################


SIMV = $(abspath simv)
WAVE ?= 0

BASIC_TRACE_TR = $(addprefix out/, $(addsuffix /trace.tr, $(BASIC_TEST)))

.PRECIOUS: $(BASIC_TRACE_TR)

all: basic_test

basic_test: $(addsuffix .basic.run, $(BASIC_TEST))

simv:
	$(VCS) $(VCS_FLAGS) -f sv.include $(INCDIR) $(VCS_DEFINES) -l vcs.log | $(HIGHLIGHT)


out/%/trace.tr:
	mkdir -p out/
	mkdir -p out/$*
	python $*.py > $@

%.basic.run: simv out/%/trace.tr
	(cd out/$*; $(SIMV) +wave=$(WAVE) +checker=basic -l simv.log)

%.dve:
	$(DVE) -full64 -vpd out/$*/vcdplus.vpd &

summary:
	@$(foreach test, $(BASIC_TEST), grep -H --color -e "BSG_FINISH" -e "BSG_FATAL" \
			-e "Error" -e "BSG_ERROR" out/$(test)/simv.log;)


















clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -rf simv.daidir simv.vdb vcs.log
	rm -rf ucli.key vcdplus.vpd simv cm.log *.tar.gz
	rm -rf stack.info.* *.pyc
	rm -rf out
