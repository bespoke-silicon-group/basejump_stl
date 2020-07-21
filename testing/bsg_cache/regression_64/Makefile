include ../../../../bsg_cadenv/cadenv.mk
export BASEJUMP_STL_DIR = $(abspath ../../..)

INCDIR =  +incdir+$(BASEJUMP_STL_DIR)/bsg_misc

VCS_FLAGS =  -full64 +lint=all,noSVA-UA,noSVA-NSVU,noVCDE -debug_access
VCS_FLAGS += +v2k -sverilog -timescale=1ps/1ps -O4

###### TEST SUITE ######
BASIC_TEST += test_random1
BASIC_TEST += test_random2
BASIC_TEST += test_random3
BASIC_TEST += test_atomic1
BASIC_TEST += test_atomic2
BASIC_TEST += test_atomic3
BASIC_TEST += test_atomic4
BASIC_TEST += test_stride1

########################

HIGHLIGHT = grep --color -E '^|Fatal|Error|Warning|Implicit wire is used|Too few instance port connections|Port connection width mismatch|Width mismatch'


### Test parameters ###
YUMI_MIN_DELAY_P  ?= 0
YUMI_MAX_DELAY_P  ?= 0
DMA_READ_DELAY_P  ?= 0
DMA_WRITE_DELAY_P ?= 0
DMA_REQ_DELAY_P   ?= 0
DMA_DATA_DELAY_P  ?= 0

VCS_DEFINES += +define+YUMI_MIN_DELAY_P=$(YUMI_MIN_DELAY_P)
VCS_DEFINES += +define+YUMI_MAX_DELAY_P=$(YUMI_MAX_DELAY_P)

VCS_DEFINES += +define+DMA_READ_DELAY_P=$(DMA_READ_DELAY_P)
VCS_DEFINES += +define+DMA_WRITE_DELAY_P=$(DMA_WRITE_DELAY_P)
VCS_DEFINES += +define+DMA_REQ_DELAY_P=$(DMA_REQ_DELAY_P)
VCS_DEFINES += +define+DMA_DATA_DELAY_P=$(DMA_DATA_DELAY_P)
#######################


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
	rm -rf csrc simv
	rm -rf simv.daidir simv.vdb vcs.log
	rm -rf ucli.key vcdplus.vpd simv cm.log *.tar.gz
	rm -rf stack.info.* *.pyc
	rm -rf out
	rm -f ../common/*.pyc
