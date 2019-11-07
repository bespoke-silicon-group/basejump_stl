#
# Makefile
#
include ../../../../bsg_cadenv/cadenv.mk
export BASEJUMP_STL_DIR = $(abspath ../../..)


INCDIR =  +incdir+$(BASEJUMP_STL_DIR)/bsg_misc/
INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_cache/

VCS_FLAGS =  -full64 +lint=all,noSVA-UA,noSVA-NSVU,noVCDE -debug_access
VCS_FLAGS += +v2k -sverilog -timescale=1ps/1ps -O4
#VCS_FLAGS += -lca -cm line+cond+fsm+tgl+branch+assert

#### Test Suite #####

TEST_SUITE = test_stride test_random test_square test_block test_zorder test_byte \
						 test_random_flush test_random_afl test_random_aflinv test_clean_read


#####################

HIGHLIGHT = grep --color -E '^|Fatal|Error|Warning|Implicit wire is used|Too few instance port connections|Port connection width mismatch|Width mismatch'


.PHONY: dve sim all clean

### TEST parameters ####

MISS_FIFO_ELS_P   = 32
DMA_READ_DELAY_P  = 64
DMA_WRITE_DELAY_P = 64
YUMI_MIN_DELAY_P  = 0
YUMI_MAX_DELAY_P  = 4

VCS_DEFINE =  +define+MISS_FIFO_ELS_P=$(MISS_FIFO_ELS_P)
VCS_DEFINE += +define+DMA_READ_DELAY_P=$(DMA_READ_DELAY_P)
VCS_DEFINE += +define+DMA_WRITE_DELAY_P=$(DMA_WRITE_DELAY_P)
VCS_DEFINE += +define+YUMI_MIN_DELAY_P=$(YUMI_MIN_DELAY_P)
VCS_DEFINE += +define+YUMI_MAX_DELAY_P=$(YUMI_MAX_DELAY_P)

########################

SIMV = $(abspath simv)
WAVE ?= 0

all: $(addsuffix .run, $(TEST_SUITE))

simv:
	$(VCS) $(VCS_FLAGS) -f sv.include $(INCDIR) $(VCS_DEFINE) -l vcs.log | $(HIGHLIGHT)
	
out/%/trace.tr:
	mkdir -p out/
	mkdir -p out/$*
	python $*.py > $@

%.run: simv out/%/trace.tr
	(cd out/$*; $(SIMV) +wave=$(WAVE) -l simv.log)

%.dve:
	$(DVE) -full64 -vpd out/$*/vcdplus.vpd &

cov:
	$(DVE) -full64 -cov -dir simv.vdb &

summary:
	@$(foreach test, $(TEST_SUITE), grep -H --color -e "BSG_FINISH" -e "BSG_FATAL" out/$(test)/simv.log;)

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -rf simv.daidir simv.vdb vcs.log
	rm -f ucli.key vcdplus.vpd simv cm.log *.tar.gz
	rm -rf stack.info.* *.pyc
	rm -rf out
