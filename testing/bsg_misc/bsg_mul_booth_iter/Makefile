BSG_MODULE_NAME=bsg_mul_booth_iter
BSG_STL_ROOT=./../../..

vcs:
	vcs -full64 -cc gcc-4.8 -cpp g++-4.8 -sverilog \
	$(BSG_STL_ROOT)/bsg_misc/bsg_defines.v \
	$(BSG_STL_ROOT)/bsg_misc/bsg_adder_carry_save_4_2.v \
	$(BSG_STL_ROOT)/bsg_misc/bsg_adder_carry_save.v \
	$(BSG_STL_ROOT)/bsg_misc/bsg_adder_wallace_tree.v \
	$(BSG_STL_ROOT)/bsg_misc/bsg_mul_booth_iter.v \
	$(BSG_STL_ROOT)/bsg_test/bsg_nonsynth_clock_gen.v \
	$(BSG_STL_ROOT)/bsg_test/bsg_nonsynth_reset_gen.v \
	./bsg_test.v
	./simv

clean:
	rm -rf simv*
	rm -rf csrc
	rm ucli.key

	
	