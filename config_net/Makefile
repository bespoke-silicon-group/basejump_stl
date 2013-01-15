include Makefile.cadenv

VCS_FLAGS = -o $@ +v2k +vc -sverilog -timescale=1ns/1ps +vcs+lic+wait +multisource_int_delays +neg_tchk +libext+.v+.vlib+.vh 

HDL_SOURCE = config_node.v config_net_tb.v

all: sim

clean:
	rm -rf testbench csrc testbench.daidir .vcsmx_rebuild *.log *.dump *.vcd

testbench: $(HDL_SOURCE)
	$(VCS) $(VCS_FLAGS) $(HDL_SOURCE) 2>&1 | tee $@.log

sim: testbench
	./testbench

