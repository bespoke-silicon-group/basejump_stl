TRACE_FILE = trace_master_0.tr
TRACE_ROM = bsg_trace_master_rom

all: sim

$(TRACE_ROM).v: $(TRACE_FILE)
	python $(BSG_IP_CORES_ROOT)/bsg_mem/bsg_ascii_to_rom.py trace_master_0.tr $(TRACE_ROM) \
	> $(TRACE_ROM).v

sim: $(TRACE_ROM).v
	vcs -f sv.include +v2k -R +lint=all -sverilog -full64 \
		-debug_pp -timescale=1ps/1ps \
    +notimingcheck

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -f $(TRACE_ROM).v
	rm -rf simv.daidir
	rm -f ucli.key vcdplus.vpd simv

.PHONY: dve sim all clean
