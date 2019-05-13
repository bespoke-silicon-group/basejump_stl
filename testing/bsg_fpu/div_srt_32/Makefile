BSG_ROOT=../../..

float32:
	make clean
	vcs -full64 -sverilog -cc gcc-4.8 -cpp g++-4.8 \
	$(BSG_ROOT)/bsg_misc/bsg_defines.v \
	$(BSG_ROOT)/bsg_test/bsg_nonsynth_clock_gen.v \
	$(BSG_ROOT)/bsg_test/bsg_nonsynth_reset_gen.v \
	$(BSG_ROOT)/bsg_misc/bsg_adder_carry_save.v \
	$(BSG_ROOT)/bsg_misc/bsg_div_srt_sel_rom.v \
	$(BSG_ROOT)/bsg_misc/bsg_scan.v \
	$(BSG_ROOT)/bsg_misc/bsg_encode_one_hot.v \
	$(BSG_ROOT)/bsg_misc/bsg_priority_encode_one_hot_out.v \
	$(BSG_ROOT)/bsg_misc/bsg_priority_encode.v \
	$(BSG_ROOT)/bsg_misc/bsg_counting_leading_zeros.v \
	$(BSG_ROOT)/bsg_misc/bsg_div_srt.v \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_pkg.v \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_preprocess.v \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_round_n.v \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_div_n.v \
	bsg_test_dpi.c \
	test_bsg_float32.v 

	./simv > rep.txt


fpu_round_n:
	make clean
	vcs -full64 -sverilog -cc gcc-4.8 -cpp g++-4.8 \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_pkg.v \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_round_n.v \
	test_bsg_round.v
	
	./simv

clean:
	rm -rf csrc
	rm -rf simv*
	rm -f ucli.key

