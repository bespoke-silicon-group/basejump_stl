include Makefile.cadenv

GTECH_DIR = $(SYNOPSYS)/icc/F-2011.09-SP5/packages/gtech/src_ver
GTECH_SIM_LIB = $(SYNOPSYS)/icc/F-2011.09-SP5/packages/gtech/src_ver/gtech_lib.v

VCS_FLAGS = -o $@ +v2k +vc -sverilog -full64 -timescale=1ns/1ps +vcs+lic+wait +multisource_int_delays +neg_tchk +libext+.v+.vlib+.vh

TESTBENCH = config_net_tb.v
HDL_SOURCE = $(GTECH_DIR)/GTECH_NAND2.v rNandMeta.v config_node.v relay_node.v config_driver.v config_bind.v $(TESTBENCH)

HDL_INSTALL = config_defs.v config_utils.v rNandMeta.v config_driver.v config_node.v relay_node.v config_bind.v
DIR_INSTALL = /homes/luzh/raw/crudo/src/parts/verilog/config_net

all: testfile testbench simulator sim

install:
	cp ${HDL_INSTALL} ${DIR_INSTALL} 

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

