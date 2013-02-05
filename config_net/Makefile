include Makefile.cadenv

VCS_FLAGS = -o $@ +v2k +vc -sverilog -timescale=1ns/1ps +vcs+lic+wait +multisource_int_delays +neg_tchk +libext+.v+.vlib+.vh 

HDL_SOURCE = config_in_s.v config_node.v relay_node.v config_driver.v bind_node.v config_net_tb.v

all: testfile testbench simulator sim

clean:
	rm -rf simulator csrc simulator.daidir .vcsmx_rebuild sc_test.in config_net_tb.v *.log *.dump *.vcd

testfile:
	./gen_tb.py -w sc_test.in 20

testbench:
	./gen_tb.py -r sc_test.in

simulator: $(HDL_SOURCE)
	$(VCS) $(VCS_FLAGS) $(HDL_SOURCE) 2>&1 | tee $@.log

sim: simulator
	./simulator 2>&1 | tee $@.log

