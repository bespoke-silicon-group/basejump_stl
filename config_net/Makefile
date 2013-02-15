include Makefile.cadenv

VCS_FLAGS = -o $@ +v2k +vc -sverilog -timescale=1ns/1ps +vcs+lic+wait +multisource_int_delays +neg_tchk +libext+.v+.vlib+.vh 

TESTBENCH = config_net_tb.v
HDL_SOURCE = config_s.v utils.v config_node.v relay_node.v config_driver.v bind_node.v tile.v $(TESTBENCH)

all: testfile testbench simulator sim

clean:
	rm -rf simulator csrc simulator.daidir .vcsmx_rebuild sc_spec.out sc_test.in $(TESTBENCH) *.log *.dump *.vcd

testfile:
	./gen_tb.py -w sc_test.in 20

testbench:
	./gen_tb.py -r sc_test.in

simulator: $(HDL_SOURCE)
	$(VCS) $(VCS_FLAGS) $(HDL_SOURCE) 2>&1 | tee $@.log

sim: simulator
	./simulator 2>&1 | tee $@.log

