BSG_ROOT=../../..

float32:
	make clean
	vcs -full64 -sverilog -cc gcc-4.8 -cpp g++-4.8 \
	$(BSG_ROOT)/bsg_misc/bsg_defines.v \
	$(BSG_ROOT)/bsg_test/bsg_nonsynth_clock_gen.v \
	$(BSG_ROOT)/bsg_test/bsg_nonsynth_reset_gen.v \
	$(BSG_ROOT)/bsg_misc/bsg_adder_carry_save.v \
	$(BSG_ROOT)/bsg_misc/bsg_div_srt_sel_rom.v \
	$(BSG_ROOT)/bsg_misc/bsg_div_srt_core.v \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_pkg.v \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_preprocess.v \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_round.v \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_div.v \
	bsg_test_dpi.cpp \
	test_bsg_float32.v 

	./simv


float16_exhaustive:
	make clean
	vcs -full64 -sverilog -cc gcc-4.8 -cpp g++-4.8 \
	$(BSG_ROOT)/bsg_misc/bsg_defines.v \
	$(BSG_ROOT)/bsg_test/bsg_nonsynth_clock_gen.v \
	$(BSG_ROOT)/bsg_test/bsg_nonsynth_reset_gen.v \
	$(BSG_ROOT)/bsg_misc/bsg_adder_carry_save.v \
	$(BSG_ROOT)/bsg_misc/bsg_div_srt_sel_rom.v \
	$(BSG_ROOT)/bsg_misc/bsg_div_srt_core.v \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_pkg.v \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_preprocess.v \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_round.v \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_div.v \
	bsg_test_dpi.cpp \
	test_bsg_float16.v 

	./simv

fpu_round:
	make clean
	vcs -full64 -sverilog -cc gcc-4.8 -cpp g++-4.8 \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_pkg.v \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_round.v \
	test_bsg_round.v
	
	./simv

clean:
	rm -rf csrc
	rm -rf simv*
	rm -f ucli.key
	rm -rf obj_dir

