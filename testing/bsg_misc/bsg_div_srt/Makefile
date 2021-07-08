BSG_ROOT_PATH=../../..
BSG_MISC_PATH=$(BSG_ROOT_PATH)/bsg_misc
BSG_TEST_PATH=$(BSG_ROOT_PATH)/bsg_test

main: simv
	./simv

simv: clean
	vcs -full64 -notice -sverilog -cc gcc-4.8 -cpp g++-4.8 \
	$(BSG_MISC_PATH)/bsg_defines.v \
	$(BSG_TEST_PATH)/bsg_nonsynth_clock_gen.v \
	$(BSG_TEST_PATH)/bsg_nonsynth_reset_gen.v \
	$(BSG_MISC_PATH)/bsg_adder_carry_save.v \
	$(BSG_MISC_PATH)/bsg_div_srt_sel_rom.v \
	$(BSG_MISC_PATH)/bsg_div_srt_core.v \
	$(BSG_MISC_PATH)/bsg_scan.v \
	$(BSG_MISC_PATH)/bsg_encode_one_hot.v \
	$(BSG_MISC_PATH)/bsg_priority_encode_one_hot_out.v \
	$(BSG_MISC_PATH)/bsg_priority_encode.v \
	$(BSG_MISC_PATH)/bsg_counting_leading_zeros.v \
	$(BSG_MISC_PATH)/bsg_div_srt.v \
	test_bsg.v 

#dc:
#	dc_shell -f compiledc.tcl

clean:
	rm -rf simv*
	rm -f ucli.key
	rm -rf csim
	rm -rf csrc
	rm -f default.svf
	rm -rf log
	rm -f *.pvl
	rm -f *.syn
	rm -f *.mr