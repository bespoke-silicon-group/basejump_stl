#
# Makefile
#

# export BSG_IP_CORES_DIR:=/path/to/bsg_ip_cores/

WAYS_P = 2 4 8

TRACE_ROM = bsg_trace_master_rom

INCDIR = +incdir+$(BSG_IP_CORES_DIR)/bsg_misc/
INCDIR += +incdir+$(BSG_IP_CORES_DIR)/bsg_cache/

HIGHLIGHT = grep --color -E '^|Error|Warning|Implicit wire is used|Too few instance port connections|Port connection width mismatch|Width mismatch'

.PHONY: dve all clean

all: $(foreach ways,$(WAYS_P),run.$(ways))

$(TRACE_ROM)_%way.v: trace_master_0_%way.tr
	python $(BSG_IP_CORES_DIR)/bsg_mem/bsg_ascii_to_rom.py $< $(TRACE_ROM) > $@

run.%: $(TRACE_ROM)_%way.v
	vcs +v2k -R +lint=all,noSVA-UA,noSVA-NSVU,noVCDE -sverilog -full64 -f sv.include $< $(INCDIR)\
		-debug_pp -timescale=1ps/1ps +vcs+vcdpluson $(VCS_DEFINES) +define+WAYS_P=$*\
		| $(HIGHLIGHT)

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -f $(TRACE_ROM).v
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv cm.log *.tar.gz

