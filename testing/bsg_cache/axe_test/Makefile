#
#		Makefile
#
#


INCDIR = +incdir+$(BSG_IP_CORES_DIR)/bsg_misc
INCDIR += +incdir+$(BSG_IP_CORES_DIR)/bsg_cache

VCS_LOG = vcs.log
TRACE_AXE = trace.axe

.PHONY: dve sim clean axe all

NUM_INSTR_P ?= 100000
SEED_P = $(shell shuf -i 0-4294967295 -n 1)
DEFINE = +define+NUM_INSTR_P=$(NUM_INSTR_P)

all: clean sim

bsg_trace_rom.tr:
	python trace_gen.py $(NUM_INSTR_P) $(SEED_P) > $@

bsg_trace_rom.v: bsg_trace_rom.tr
	python $(BSG_IP_CORES_DIR)/bsg_mem/bsg_ascii_to_rom.py \
		bsg_trace_rom.tr bsg_trace_rom > bsg_trace_rom.v

sim: bsg_trace_rom.v
	vcs +v2k -R -sverilog -full64 -debug_pp \
		+lint=all,noSVA-UA,noSVA-NSVU,noVCDE,noNS \
		-timescale=1ns/1ps +vcs+vcdpluson \
		-f sv.include $(INCDIR) -l $(VCS_LOG) $(DEFINE)

dve:
	dve -full64 -vpd vcdplus.vpd &

$(TRACE_AXE):
	python axe_trace_filter.py vcs.log > $(TRACE_AXE)

axe: $(TRACE_AXE)
	cat $<
	$(AXE_DIR)/src/axe check TSO $<

#shrink: $(TRACE_AXE)
#	python $(AXE_DIR)/src/axe-shrink.py TSO $(TRACE_AXE)

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv cm.log *.tar.gz $(VCS_LOG)
	rm -rf stack.info.*
	rm -f $(TRACE_AXE)
	rm -f bsg_trace_rom.tr bsg_trace_rom.v
