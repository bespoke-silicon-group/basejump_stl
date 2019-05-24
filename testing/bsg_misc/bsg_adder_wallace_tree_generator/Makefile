BSG_ROOT=../../..

main: simv
	./simv
simv: bsg_adder_wallace_tree_32.v
	vcs -full64 -sverilog -cc gcc-4.8 -cpp g++-4.8 \
	$(BSG_ROOT)/bsg_misc/bsg_adder_carry_save.v \
	./bsg_adder_wallace_tree_32.v \
	./test_bsg.v

bsg_adder_wallace_tree_32.v:
	python3 $(BSG_ROOT)/bsg_misc/bsg_adder_wallace_tree_generator.py 32

clean:
	rm -rf csrc simv* ucli.key