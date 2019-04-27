INCDIR = +incdir+$(BASEJUMP_STL_DIR)/bsg_misc

FPU_TRACE_ROM = bsg_fpu_trace_rom

all: sim

$(FPU_TRACE_ROM).tr:
	python add_sub_trace_gen.py > $@

$(FPU_TRACE_ROM).v: $(FPU_TRACE_ROM).tr
	python $(BASEJUMP_STL_DIR)/bsg_mem/bsg_ascii_to_rom.py $< $(FPU_TRACE_ROM) > $@

sim: $(FPU_TRACE_ROM).v
	vcs +v2k -R -sverilog -full64 -debug_pp \
		-timescale=1ps/1ps +vcs+vcdpluson \
		-f sv.include $(INCDIR) -l vcs.log


clean:
	rm -f vcdplus.vpd vcs.log ucli.key simv
	rm -rf csrc simv.daidir
	rm -f $(FPU_TRACE_ROM).tr $(FPU_TRACE_ROM).v
