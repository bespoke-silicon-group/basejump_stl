#
# Makefile
#
include ../../../../bsg_cadenv/cadenv.mk
export BASEJUMP_STL_DIR = $(abspath ../../..)


INCDIR = +incdir+$(BASEJUMP_STL_DIR)/bsg_misc/
INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_cache/

VCS_FLAGS = +v2k -sverilog -timescale=1ps/1ps -O4

ifeq ($(WAVE), 1)
VCS_FLAGS += +vcs+vcdpluson
endif

ifeq ($(LOG), 1)
VCS_FLAGS += -l vcs.log
endif


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


all: sim

TRACE_TR = trace.tr
TRACE_GEN_PY = trace_gen.py
TRACE_ROM = trace_rom

$(TRACE_TR): $(TRACE_GEN_PY)
	python $(TRACE_GEN_PY) > $(TRACE_TR)

sim: $(TRACE_TR)
	$(VCS) -full64 -R +lint=all,noSVA-UA,noSVA-NSVU,noVCDE \
	  -f sv.include $(INCDIR) \
		$(VCS_FLAGS) $(VCS_DEFINE) \
		| $(HIGHLIGHT)

dve:
	$(DVE) -full64 -vpd vcdplus.vpd &

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv cm.log *.tar.gz vcs.log
	rm -rf stack.info.*
	rm -f $(TRACE_TR)

