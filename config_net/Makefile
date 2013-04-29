include Makefile.cadenv

GTECH_DIR = $(SYNOPSYS)/icc/F-2011.09-SP5/packages/gtech/src_ver
GTECH_SIM_LIB = $(SYNOPSYS)/icc/F-2011.09-SP5/packages/gtech/src_ver/gtech_lib.v

VCS_FLAGS = -o $@ +v2k +vc -sverilog -full64 -timescale=1ns/1ps +vcs+lic+wait +multisource_int_delays +neg_tchk +libext+.v+.vlib+.vh +define+CONFIG_SETTER_BY_FILE +define+CONFIG_PROBES

TESTBENCH = config_net_tb.v
HDL_SOURCE = $(GTECH_DIR)/GTECH_NAND2.v rNandMeta.v config_node.v relay_node.v config_vector.v config_node_bind.v $(TESTBENCH)

HDL_INSTALL = config_defs.v config_utils.v rNandMeta.v config_node.v relay_node.v config_node_bind.v config_vector.v
DIR_INSTALL = /homes/luzh/raw/crudo/src/parts/verilog/config_net

all: testfile testbench simulator sim

install:
	cp ${HDL_INSTALL} ${DIR_INSTALL} 

clean:
	rm -rf simulator csrc simulator.daidir .vcsmx_rebuild config_spec.out config_test.in config_vector.in config_probe.in $(TESTBENCH) *.log *.dump *.vcd ucli.key

testfile:
	./gen_tb.py -w config_test.in 20

testbench:
	./gen_tb.py -r config_test.in

simulator: $(HDL_SOURCE)
	$(VCS) $(VCS_FLAGS) $(HDL_SOURCE) 2>&1 | tee $@.log

sim: simulator
	./simulator 2>&1 | tee $@.log

