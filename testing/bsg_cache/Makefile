TRACE_FILE = trace_master_0.tr
TRACE_ROM = bsg_trace_master_rom
INCDIR = +incdir+$(abspath $(BSG_IP_CORES_ROOT))/bsg_misc/


all: sim

$(TRACE_ROM).v: $(TRACE_FILE)
	python $(BSG_IP_CORES_ROOT)/bsg_mem/bsg_ascii_to_rom.py trace_master_0.tr $(TRACE_ROM) \
	> $(TRACE_ROM).v

sim: $(TRACE_ROM).v
	vcs +v2k -R +lint=all -sverilog -full64 -f sv.include $(INCDIR)\
		-debug_pp -timescale=1ps/1ps \
    +notimingcheck -cm line+cond+fsm+tgl+path+branch+assert \
		-cm_line contassign	-lca \
		-cm_name code_cov

dve:
	dve -full64 -vpd vcdplus.vpd &

cov:
	dve -full64 -covdir simv.vdb/ &


clean:
	rm -rf DVEfiles
	rm -rf csrc
	rm -f $(TRACE_ROM).v
	rm -rf simv.daidir simv.vdb
	rm -f ucli.key vcdplus.vpd simv cm.log

.PHONY: dve sim all clean
