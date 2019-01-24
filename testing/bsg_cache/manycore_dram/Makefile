#
# Makefile
#

# include dirs
INCDIR = +incdir+$(BSG_IP_CORES_DIR)/bsg_misc/
INCDIR += +incdir+$(BSG_IP_CORES_DIR)/bsg_cache/
INCDIR += +incdir+$(BSG_IP_CORES_DIR)/bsg_noc/
INCDIR += +incdir+$(BSG_MANYCORE_DIR)/v/
INCDIR += +incdir+$(BSG_IP_CORES_DIR)/testing/bsg_dram_ctrl/lpddr_dram_model

# DRAM settings
VCS_DEFINES += +define+den2048Mb
VCS_DEFINES += +define+sg75
VCS_DEFINES += +define+x16
VCS_DEFINES += +define+FULL_MEM

HIGHLIGHT = grep --color -E '^|Error|Warning|Implicit wire is used|Too few instance port connections|Port connection width mismatch|Width mismatch'

.PHONY: dve sim all clean

all: sim

sim:
	vcs +v2k -R +lint=all,noSVA-UA,noSVA-NSVU,noVCDE -sverilog -full64 -f sv.include $(INCDIR) \
		-debug_pp -timescale=1ps/1ps +vcs+vcdpluson $(VCS_DEFINES) -l vcs.log\
		| $(HIGHLIGHT)

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv *.tar.gz vcs.log

