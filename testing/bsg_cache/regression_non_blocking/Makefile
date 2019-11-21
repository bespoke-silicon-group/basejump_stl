#
# Makefile
#
include ../../../../bsg_cadenv/cadenv.mk
export BASEJUMP_STL_DIR = $(abspath ../../..)


INCDIR =  +incdir+$(BASEJUMP_STL_DIR)/bsg_misc/
INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_cache/

VCS_FLAGS =  -full64 +lint=all,noSVA-UA,noSVA-NSVU,noVCDE -debug_access
VCS_FLAGS += +v2k -sverilog -timescale=1ps/1ps -O4

#### Test Suite #####

BASIC_TEST =  test_stride test_random test_square test_block test_zorder test_byte
BASIC_TEST += test_linear test_long_interval test_burst
BASIC_TEST += test_random_flush test_random_afl test_random_aflinv test_random_aflinv2
BASIC_TEST += test_clean_read test_invalid_lock test_invalid_lock2 test_pe_cover
BASIC_TEST += test_alock test_random_tagfl test_ld_st

TAG_TEST = test_tag_access

AINV_TEST = test_ainv

BLOCK_LD_TEST = test_block_ld test_block_ld2 test_block_ld3

#####################

HIGHLIGHT = grep --color -E '^|Fatal|Error|Warning|Implicit wire is used|Too few instance port connections|Port connection width mismatch|Width mismatch'


.PHONY: dve sim all clean

### TEST parameters ####

MISS_FIFO_ELS_P   = 32
DMA_READ_DELAY_P  = 64
DMA_WRITE_DELAY_P = 64
DMA_DATA_DELAY_P  = 4
DMA_REQ_DELAY_P  = 4
YUMI_MIN_DELAY_P  = 0
YUMI_MAX_DELAY_P  = 4

VCS_DEFINE =  +define+MISS_FIFO_ELS_P=$(MISS_FIFO_ELS_P)
VCS_DEFINE += +define+DMA_READ_DELAY_P=$(DMA_READ_DELAY_P)
VCS_DEFINE += +define+DMA_WRITE_DELAY_P=$(DMA_WRITE_DELAY_P)
VCS_DEFINE += +define+DMA_DATA_DELAY_P=$(DMA_DATA_DELAY_P)
VCS_DEFINE += +define+DMA_REQ_DELAY_P=$(DMA_REQ_DELAY_P)
VCS_DEFINE += +define+YUMI_MIN_DELAY_P=$(YUMI_MIN_DELAY_P)
VCS_DEFINE += +define+YUMI_MAX_DELAY_P=$(YUMI_MAX_DELAY_P)

########################

SIMV = $(abspath simv)
WAVE ?= 0

BASIC_TRACE_TR = $(addprefix out/, $(addsuffix /trace.tr, $(BASIC_TEST)))
TAG_TRACE_TR = $(addprefix out/, $(addsuffix /trace.tr, $(TAG_TEST)))
AINV_TRACE_TR = $(addprefix out/, $(addsuffix /trace.tr, $(AINV_TEST)))
BLOCK_LD_TRACE_TR = $(addprefix out/, $(addsuffix /trace.tr, $(BLOCK_LD_TEST)))

.PRECIOUS: $(BASIC_TRACE_TR) $(TAG_TRACE_TR) $(AINV_TRACE_TR)

all: basic_test tag_test ainv_test block_ld_test

basic_test: $(addsuffix .basic.run, $(BASIC_TEST))
tag_test: $(addsuffix .tag.run, $(TAG_TEST))
ainv_test: $(addsuffix .ainv.run, $(AINV_TEST))
block_ld_test: $(addsuffix .block_ld.run, $(BLOCK_LD_TEST))

# coverage options
CM_OPT = -cm line+fsm+branch+cond+tgl

simv:
	$(VCS) $(VCS_FLAGS) $(CM_OPT) -f sv.include $(INCDIR) $(VCS_DEFINE) -l vcs.log | $(HIGHLIGHT)

out/%/trace.tr:
	mkdir -p out/
	mkdir -p out/$*
	python $*.py > $@

%.basic.run: simv out/%/trace.tr
	(cd out/$*; $(SIMV) +wave=$(WAVE) +checker=basic -l simv.log $(CM_OPT) -cm_name $*)

%.tag.run: simv out/%/trace.tr
	(cd out/$*; $(SIMV) +wave=$(WAVE) +checker=tag -l simv.log $(CM_OPT) -cm_name $*)

%.ainv.run: simv out/%/trace.tr
	(cd out/$*; $(SIMV) +wave=$(WAVE) +checker=ainv -l simv.log $(CM_OPT) -cm_name $*)

%.block_ld.run: simv out/%/trace.tr
	(cd out/$*; $(SIMV) +wave=$(WAVE) +checker=block_ld -l simv.log $(CM_OPT) -cm_name $*)

%.dve:
	$(DVE) -full64 -vpd out/$*/vcdplus.vpd &

cov:
	$(DVE) -full64 -cov -session cov.tcl &

summary:
	@$(foreach test, $(BASIC_TEST), grep -H --color -e "BSG_FINISH" -e "BSG_FATAL" \
			-e "Error" -e "BSG_ERROR" out/$(test)/simv.log;)
	@$(foreach test, $(TAG_TEST), grep -H --color -e "BSG_FINISH" -e "BSG_FATAL" \
			-e "Error" -e "BSG_ERROR" out/$(test)/simv.log;)
	@$(foreach test, $(AINV_TEST), grep -H --color -e "BSG_FINISH" -e "BSG_FATAL" \
			-e "Error" -e "BSG_ERROR" out/$(test)/simv.log;)
	@$(foreach test, $(BLOCK_LD_TEST), grep -H --color -e "BSG_FINISH" -e "BSG_FATAL" \
			-e "Error" -e "BSG_ERROR" out/$(test)/simv.log;)

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -rf simv.daidir simv.vdb vcs.log
	rm -f ucli.key vcdplus.vpd simv cm.log *.tar.gz
	rm -rf stack.info.* *.pyc
	rm -rf out
