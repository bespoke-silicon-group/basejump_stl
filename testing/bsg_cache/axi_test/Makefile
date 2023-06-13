#
#		Makefile
#
#

include ../../../../bsg_cadenv/cadenv.mk
export BASEJUMP_STL_DIR=$(abspath ../../..)
INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_misc
INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_cache

VCS_LOG = vcs.log
TRACE_AXE = bsg_cache.axe

.PHONY: dve sim clean all

all: sim

bsg_trace_rom.tr:
	python trace_basic.py > $@

bsg_trace_rom.sv: bsg_trace_rom.tr
	python $(BASEJUMP_STL_DIR)/bsg_mem/bsg_ascii_to_rom.py \
		bsg_trace_rom.tr bsg_trace_rom > bsg_trace_rom.sv

sim: bsg_trace_rom.sv
	vcs +v2k -R -sverilog -full64 \
		+lint=all,noSVA-UA,noSVA-NSVU,noVCDE,noNS \
		-timescale=1ns/1ps +vcs+vcdpluson -assert svaext \
		-f sv.include $(INCDIR) -l $(VCS_LOG) $(DEFINE)

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -rf simv.daidir simv.vdb vc_hdrs.h
	rm -f ucli.key vcdplus.vpd simv cm.log *.tar.gz $(VCS_LOG)
	rm -rf stack.info.*
	rm -f $(TRACE_AXE)
	rm -f bsg_trace_rom.tr bsg_trace_rom.sv
