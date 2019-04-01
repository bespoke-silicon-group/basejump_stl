#
# Makefile
#


# export BSG_IP_CORES_DIR:=/path/to/bsg_ip_cores/

TRACE_FILE = trace_master_0.tr
TRACE_ROM = bsg_trace_master_rom

INCDIR = +incdir+$(BSG_IP_CORES_DIR)/bsg_misc/
INCDIR += +incdir+$(BSG_IP_CORES_DIR)/bsg_cache/

HIGHLIGHT = grep --color -E '^|Error|Warning|Implicit wire is used|Too few instance port connections|Port connection width mismatch|Width mismatch'

.PHONY: dve sim all clean sim_hard

all: sim sim_hard

$(TRACE_ROM).v: $(TRACE_FILE)
	python $(BSG_IP_CORES_DIR)/bsg_mem/bsg_ascii_to_rom.py $(TRACE_FILE) $(TRACE_ROM) \
	> $(TRACE_ROM).v

# vcs options for hardened simulation
sim_hard: VCS_OPTIONS =  +v2k
sim_hard: VCS_OPTIONS += -R
sim_hard: VCS_OPTIONS += +lint=all,noSVA-UA,noSVA-NSVU,noVCDE,noNS
sim_hard: VCS_OPTIONS += +define+TSMC_UNIT_DELAY
sim_hard: VCS_OPTIONS += +define+TSCM_NO_WARNING
sim_hard: VCS_OPTIONS += -sverilog
sim_hard: VCS_OPTIONS += -full64

sim_hard sim: $(TRACE_ROM).v
	vcs $(VCS_OPTIONS) -f sv.include $(INCDIR)\
		-debug_pp -timescale=1ps/1ps +vcs+vcdpluson $(VCS_DEFINES)\
		| $(HIGHLIGHT)

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -f $(TRACE_ROM).v
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv cm.log *.tar.gz

