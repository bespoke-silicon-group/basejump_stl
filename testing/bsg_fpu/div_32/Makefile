BSG_ROOT=../../..


verilator_wrapper:
	make clean
	verilator --Wno-fatal -sv --cc \
	$(BSG_ROOT)/bsg_misc/bsg_defines.v \
	$(BSG_ROOT)/bsg_misc/bsg_adder_carry_save.v \
	$(BSG_ROOT)/bsg_misc/bsg_div_srt_sel_rom.v \
	$(BSG_ROOT)/bsg_misc/bsg_div_srt_core.v \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_pkg.v \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_preprocess.v \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_round.v \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_div.v \
	./verilator/test_bsg_float16_wrapper.v \
	--exe \ ./verilator/test_bsg_float16.cpp \
	--top-module bsg_fpu_div_float16 \
	-CFLAGS "-g -O3" \
	-LDFLAGS "-lpthread"

	make -C obj_dir -f Vbsg_fpu_div_float16.mk 

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
	./vcs/bsg_test_dpi.cpp \
	./vcs/test_bsg_float32.v 

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
	./vcs/bsg_test_dpi.cpp \
	./vcs/test_bsg_float16.v 

	./simv

fpu_round:
	make clean
	vcs -full64 -sverilog -cc gcc-4.8 -cpp g++-4.8 \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_pkg.v \
	$(BSG_ROOT)/bsg_fpu/bsg_fpu_round.v \
	./vcs/test_bsg_round.v
	
	./simv

clean:
	rm -rf obj_dir
	rm -rf csrc
	rm -rf simv*
	rm -f ucli.key
	rm -rf obj_dir

