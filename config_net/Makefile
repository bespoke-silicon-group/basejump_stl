include cadenv.mk

GTECH_DIR = $(SYNOPSYS)/icc/F-2011.09-SP5/packages/gtech/src_ver
GTECH_SIM_LIB = $(SYNOPSYS)/icc/F-2011.09-SP5/packages/gtech/src_ver/gtech_lib.v

VCS_FLAGS = -o $@ +v2k +vc -sverilog -full64 -timescale=1ns/1ps +vcs+lic+wait +multisource_int_delays +neg_tchk +libext+.v+.vlib+.vh

TESTBENCH = config_net_tb.v
HDL_SOURCE = $(GTECH_DIR)/GTECH_NAND2.v rNandMeta.v config_node.v relay_node.v config_snooper.v config_setter.v config_file_setter.v config_node_bind.v $(TESTBENCH)

HDL_INSTALL = config_defs.v config_utils.v rNandMeta.v config_node.v relay_node.v config_node_bind.v config_setter.v config_file_setter.v
HDL_INSTALL_DIR = /homes/luzh/raw/crudo/src/parts/verilog/config_net

PY_INSTALL_DIR = /homes/luzh/raw/greenlight/module_tests/config_node/common

all: testfile testbench simulator sim

install:
	cp ${HDL_INSTALL} ${HDL_INSTALL_DIR} 
	cp gen_tb.py ${PY_INSTALL_DIR} 

clean:
	rm -rf simulator csrc simulator.daidir .vcsmx_rebuild config_spec.out config_test.in config_file_setter.in config_probe.in $(TESTBENCH) *.log *.dump *.vcd ucli.key

testfile:
	./gen_tb.py -w config_test.in 20

testbench:
	./gen_tb.py -r config_test.in -o config_net_tb.v

simulator: $(HDL_SOURCE)
	$(VCS) $(VCS_FLAGS) $(HDL_SOURCE) 2>&1 | tee $@.log

sim: simulator
	./simulator +config-file-setter +config-node-bind 2>&1 | tee $@.log

