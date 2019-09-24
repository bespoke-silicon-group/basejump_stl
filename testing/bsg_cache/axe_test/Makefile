#
#		Makefile
#
#

include ../../../../bsg_cadenv/cadenv.mk
export BASEJUMP_STL_DIR=$(abspath ../../..)
INCDIR = +incdir+$(BASEJUMP_STL_DIR)/bsg_misc

VCS_LOG = vcs.log
TRACE_AXE = bsg_cache.axe

.PHONY: dve sim clean axe all

NUM_INSTR_P ?= 50000
WAYS_P ?= 2
DATA_WIDTH_P ?= 32
SEED_P ?= $(shell shuf -i 0-4294967295 -n 1)
DEFINE = +define+NUM_INSTR_P=$(NUM_INSTR_P)
DEFINE += +define+WAYS_P=$(WAYS_P)
DEFINE += +define+DATA_WIDTH_P=$(DATA_WIDTH_P)

all: clean sim

bsg_trace_rom.tr:
	python axe_trace_gen.py $(NUM_INSTR_P) $(SEED_P) $(WAYS_P) $(DATA_WIDTH_P) > $@

bsg_trace_rom.v: bsg_trace_rom.tr
	python $(BASEJUMP_STL_DIR)/bsg_mem/bsg_ascii_to_rom.py \
		bsg_trace_rom.tr bsg_trace_rom > bsg_trace_rom.v

sim: bsg_trace_rom.v
	vcs +v2k -R -sverilog -full64 \
		+lint=all,noSVA-UA,noSVA-NSVU,noVCDE,noNS \
		-timescale=1ns/1ps +vcs+vcdpluson \
		-f sv.include $(INCDIR) -l $(VCS_LOG) $(DEFINE)

dve:
	dve -full64 -vpd vcdplus.vpd &

axe: $(TRACE_AXE)
	cat $<
	$(AXE_DIR)/src/axe check TSO $<


clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv cm.log *.tar.gz $(VCS_LOG)
	rm -rf stack.info.*
	rm -f $(TRACE_AXE)
	rm -f bsg_trace_rom.tr bsg_trace_rom.v
