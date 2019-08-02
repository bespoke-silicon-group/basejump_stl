#
# Makefile
#
include ../../../../bsg_cadenv/cadenv.mk
TRACE_FILE = trace_master_0.tr
TRACE_ROM = bsg_trace_master_rom

INCDIR = +incdir+$(BSG_IP_CORES_DIR)/bsg_misc/
INCDIR += +incdir+$(BSG_IP_CORES_DIR)/bsg_cache/

HIGHLIGHT = grep --color -E '^|Error|Warning|Implicit wire is used|Too few instance port connections|Port connection width mismatch|Width mismatch'


.PHONY: dve sim all clean

all: sim

$(TRACE_ROM).v: $(TRACE_FILE)
	python $(BSG_IP_CORES_DIR)/bsg_mem/bsg_ascii_to_rom.py $(TRACE_FILE) $(TRACE_ROM) \
	> $(TRACE_ROM).v

sim: $(TRACE_ROM).v
	vcs +v2k -R +lint=all,noSVA-UA,noSVA-NSVU,noVCDE -sverilog -full64 -f sv.include $(INCDIR)\
		-timescale=1ps/1ps +vcs+vcdpluson $(VCS_DEFINES) -l vcs.log\
		| $(HIGHLIGHT)

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -f $(TRACE_ROM).v
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv cm.log *.tar.gz vcs.log
	rm -rf stack.info.*

