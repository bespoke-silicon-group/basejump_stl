TRACE_FILE = trace_master_0.tr
TRACE_ROM = bsg_trace_master_rom
INCDIR = +incdir+$(abspath $(BSG_IP_CORES_DIR))/bsg_misc/
INCDIR += +incdir+$(abspath $(BSG_IP_CORES_DIR))/bsg_cache/
INCDIR += +incdir+$(abspath $(BSG_IP_CORES_DIR))/bsg_noc/
INCDIR += +incdir+$(abspath $(BSG_MANYCORE_DIR))/v/
INCDIR += +incdir+$(abspath $(BSG_DESIGNS_TARGET_DIR))/testing/dram_model
VCS_DEFINES += +define+den1024Mb
VCS_DEFINES += +define+sg75
VCS_DEFINES += +define+x16
VCS_DEFINES += +define+FULL_MEM

HIGHLIGHT = grep --color -E '^|Error|Warning|Implicit wire is used|Too few instance port connections|Port connection width mismatch|Width mismatch'


all: sim

$(TRACE_ROM).v: $(TRACE_FILE)
	python $(BSG_IP_CORES_DIR)/bsg_mem/bsg_ascii_to_rom.py trace_master_0.tr $(TRACE_ROM) \
	> $(TRACE_ROM).v

sim: $(TRACE_ROM).v
	vcs +v2k -R +lint=all -sverilog -full64 -f sv.include $(INCDIR)\
		-debug_pp -timescale=1ps/1ps +vcs+vcdpluson $(VCS_DEFINES)\
		+define+TEST_MODE=1\
		| $(HIGHLIGHT)

regression: $(TRACE_ROM).v
	vcs +v2k -R +lint=all -sverilog -full64 -f sv.include $(INCDIR)\
		-debug_pp -timescale=1ps/1ps +vcs+vcdpluson $(VCS_DEFINES)\
		+define+TEST_MODE=0\
		| $(HIGHLIGHT)
	

dve:
	dve -full64 -vpd vcdplus.vpd &

cov:
	dve -full64 -covdir simv.vdb/ &


clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -f $(TRACE_ROM).v
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv cm.log *.tar.gz

.PHONY: dve sim all clean
