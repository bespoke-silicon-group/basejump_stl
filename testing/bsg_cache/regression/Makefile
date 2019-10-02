#
# Makefile
#
include ../../../../bsg_cadenv/cadenv.mk
export BASEJUMP_STL_DIR = $(abspath ../../..)

WAYS_P ?= 2

TRACE_GEN_PY = trace_way$(WAYS_P).py
TRACE_FILE = trace_way$(WAYS_P).tr
TRACE_ROM = bsg_trace_master_rom
TRACE_ROM_V = bsg_trace_master_rom_way$(WAYS_P).v

INCDIR = +incdir+$(BASEJUMP_STL_DIR)/bsg_misc/
#INCDIR += +incdir+$(BSG_IP_CORES_DIR)/bsg_cache/

DEFINE += +define+WAYS_P=$(WAYS_P)

HIGHLIGHT = grep --color -E '^|Error|Warning|Implicit wire is used|Too few instance port connections|Port connection width mismatch|Width mismatch'


.PHONY: dve sim all clean

all: sim

$(TRACE_FILE): $(TRACE_GEN_PY)
	python $(TRACE_GEN_PY) > $(TRACE_FILE)

$(TRACE_ROM_V): $(TRACE_FILE)
	python $(BASEJUMP_STL_DIR)/bsg_mem/bsg_ascii_to_rom.py $(TRACE_FILE) $(TRACE_ROM) \
	> $(TRACE_ROM_V)

sim: $(TRACE_ROM_V)
	vcs +v2k -R +lint=all,noSVA-UA,noSVA-NSVU,noVCDE \
		-sverilog -full64 -f sv.include $(INCDIR) $(TRACE_ROM_V)\
		-timescale=1ps/1ps +vcs+vcdpluson $(DEFINE) -l vcs.log\
		| $(HIGHLIGHT)

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -f $(TRACE_ROM)*.v
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv cm.log *.tar.gz vcs.log
	rm -rf stack.info.*
	rm -f *.tr

