BSG_MODULE_NAME=bsg_mul_iterative
BSG_STL_ROOT=../../../

BSG_RTL_SRC_DIR=$(BSG_STL_ROOT)/bsg_misc
BSG_TEST_SRC_DIR=$(BSG_STL_ROOT)/bsg_test

main: simv
	./simv

simv: 
	vcs -full64 -cc gcc-4.8 -cpp g++-4.8  -LDFLAGS -Wl,--no-as-needed  -sverilog \
	$(BSG_RTL_SRC_DIR)/bsg_defines.v \
	$(BSG_TEST_SRC_DIR)/bsg_nonsynth_clock_gen.v \
	$(BSG_TEST_SRC_DIR)/bsg_nonsynth_reset_gen.v \
	$(BSG_RTL_SRC_DIR)/bsg_adder_carry_save.v \
	$(BSG_RTL_SRC_DIR)/bsg_mul_iterative.v \
	./test_bsg.v 

	

test_bsg_for_synthesis.v:
	python3 ./test_bsg_for_synthesis.py

clean:
	rm -rf simv*
	rm -rf csrc ucli.key
	
	
	
