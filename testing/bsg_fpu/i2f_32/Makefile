INCDIR = +incdir+$(BASEJUMP_STL_DIR)/bsg_misc +incdir+$(BASEJUMP_STL_DIR)/bsg_fpu

FPU_TRACE_ROM = bsg_fpu_trace_rom

app:
	gcc -o app ./i2f_32.c ../common/fpu_common.c \
		-I../common -lm -std=c99

$(FPU_TRACE_ROM).tr: app
	./app > $@

$(FPU_TRACE_ROM).v: $(FPU_TRACE_ROM).tr
	python $(BASEJUMP_STL_DIR)/bsg_mem/bsg_ascii_to_rom.py $< $(FPU_TRACE_ROM) > $@

rtl_sim: $(FPU_TRACE_ROM).v
	vcs +v2k -R -sverilog -full64 -debug_pp \
		-timescale=1ps/1ps +vcs+vcdpluson \
		-f rtl_sv.include $(INCDIR) -l vcs.log

synth_sim: $(FPU_TRACE_ROM).v
	vcs +v2k -R -sverilog -full64 -debug_pp \
		-timescale=1ps/1ps +vcs+vcdpluson \
		-f synth_sv.include $(INCDIR) -l vcs.log

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -f app
	rm -f vcdplus.vpd vcs.log ucli.key simv
	rm -rf csrc simv.daidir DVEfiles
	rm -f $(FPU_TRACE_ROM).tr $(FPU_TRACE_ROM).v
